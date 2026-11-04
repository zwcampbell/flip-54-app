import Foundation
import HealthKit
import Observation
import UIKit
import WatchConnectivity
import SwiftData
import os
import Flip54Storage
import Flip54WorkoutEngine

private let log = Logger(subsystem: "com.flip54.app", category: "WatchWorkoutLink")

/// A command from the watch. `id` grows with each one, so the same command
/// twice in a row still registers as a change.
struct ReceivedWatchCommand: Equatable {
    let id: Int
    let command: RemoteWorkoutCommand
}

/// Runs a workout started on the iPhone on the Apple Watch too.
///
/// Starting a workout launches the watch app into a workout session
/// (`startWatchApp(with:)`). The watch mirrors that session back here, which
/// gives the two a channel that keeps working with the wrist down. The iPhone
/// runs the deck and sends each change down it; the watch sends back what
/// the wearer tapped, which lands in `command`. The watch records the
/// Apple Health workout; the iPhone saves History.
///
/// Workouts started on the watch run there on their own; when one finishes,
/// the watch queues it over WatchConnectivity and it's saved to History here.
///
/// The workout setup (difficulty, deck, equipment, card style) is shared both
/// ways as each side's application context, newest change winning, and the
/// deck unlocks earned in History go to the watch with it.
@MainActor
@Observable
final class WatchWorkoutLink: NSObject {
    /// Latest command from the watch.
    private(set) var command: ReceivedWatchCommand?

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var mirrored: HKWorkoutSession?
    @ObservationIgnored private var latest: RemoteWorkoutSnapshot?
    @ObservationIgnored private var commandCount = 0
    /// Recent tagged commands, so one sent over both links runs once.
    @ObservationIgnored private var seenCommandIDs: [UUID] = []
    /// Takes the watch's commands while the app is in the background, where
    /// the workout screen's `onChange` on `command` doesn't run.
    @ObservationIgnored var backgroundCommandHandler: (@MainActor (RemoteWorkoutCommand) -> Void)?
    @ObservationIgnored private let container: ModelContainer?
    /// The setup as last shared with (or taken from) the watch.
    @ObservationIgnored private var shared: SyncedSettings? {
        didSet {
            if let shared, let data = try? shared.encoded() { UserDefaults.standard.set(data, forKey: Self.sharedKey) }
        }
    }
    private static let sharedKey = "phone.sharedWatchSettings"

    init(container: ModelContainer? = nil) {
        self.container = container
        if let data = UserDefaults.standard.data(forKey: Self.sharedKey) {
            shared = try? SyncedSettings.decode(data)
        }
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        store.workoutSessionMirroringStartHandler = { [weak self] session in
            let session = UncheckedSendable(session)
            Task { @MainActor in self?.attach(session.value) }
        }
    }

    /// A paired watch has Flip 54 installed.
    private var hasWatchApp: Bool {
        WCSession.isSupported()
            && WCSession.default.activationState == .activated
            && WCSession.default.isPaired
            && WCSession.default.isWatchAppInstalled
    }

    // MARK: - From the iPhone workout

    /// A workout started (or resumed from the banner) on the iPhone.
    func workoutStarted(_ snapshot: RemoteWorkoutSnapshot) {
        latest = snapshot
        guard hasWatchApp, HKHealthStore.isHealthDataAvailable() else {
            let session = WCSession.default
            log.info("Not starting the watch: activated \(session.activationState == .activated, privacy: .public), paired \(session.isPaired, privacy: .public), app installed \(session.isWatchAppInstalled, privacy: .public)")
            return
        }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor
        Task {
            do {
                // Launching the watch into a workout needs Health access here too.
                try await store.requestAuthorization(toShare: [HKObjectType.workoutType()],
                                                     read: [HKQuantityType(.heartRate)])
            } catch {
                log.error("Health authorization failed: \(error.localizedDescription, privacy: .public)")
                return
            }
            store.startWatchApp(with: configuration) { started, error in
                if let error {
                    log.error("Couldn't start the watch app: \(error.localizedDescription, privacy: .public)")
                } else {
                    log.info("Started the watch app: \(started, privacy: .public)")
                }
            }
        }
    }

    /// The deck changed: pass it on to the watch.
    func update(_ snapshot: RemoteWorkoutSnapshot) {
        latest = snapshot
        send(.snapshot(snapshot))
    }

    /// The workout ended or was left on the iPhone.
    func workoutEnded() {
        latest = nil
        send(.ended)
        mirrored = nil
    }

    // MARK: - Mirrored session

    private func attach(_ session: HKWorkoutSession) {
        mirrored = session
        session.delegate = self
        log.info("Watch mirrored its workout session")
        // Catch the watch up, or tell it the workout's already over.
        if let latest {
            send(.snapshot(latest))
        } else {
            send(.ended)
        }
    }

    /// Sends over WatchConnectivity when the watch app can hear it, otherwise
    /// over the mirrored Health session (which needs the real device link,
    /// so it isn't there in the simulator).
    private func send(_ message: RemoteWorkoutMessage) {
        guard let data = try? message.encoded() else { return }
        let session = WCSession.default
        if WCSession.isSupported(), session.activationState == .activated, session.isReachable {
            session.sendMessageData(data, replyHandler: nil) { [weak self] error in
                log.error("Couldn't message the watch: \(error.localizedDescription, privacy: .public)")
                // Try the mirrored session instead, so the update isn't lost.
                Task { @MainActor [weak self] in self?.sendMirrored(data) }
            }
            return
        }
        sendMirrored(data)
    }

    private func sendMirrored(_ data: Data) {
        guard let mirrored else { return }
        Task {
            do {
                try await mirrored.sendToRemoteWorkoutSession(data: data)
            } catch {
                log.error("Couldn't send to the watch: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func catchUpWatch() {
        if let latest { send(.snapshot(latest)) }
    }

    private func received(_ data: Data) {
        switch try? RemoteWorkoutMessage.decode(data) {
        case .taggedCommand(let id, let command):
            guard !seenCommandIDs.contains(id) else { return }
            seenCommandIDs.append(id)
            if seenCommandIDs.count > 50 { seenCommandIDs.removeFirst() }
            deliver(command)
        case .command(let command):
            deliver(command)
        case .finished(let workout):
            save(workout)
        default:
            break
        }
    }

    /// Runs a watch command: through the workout screen in the foreground,
    /// or the background relay when the app isn't active.
    private func deliver(_ command: RemoteWorkoutCommand) {
        if let backgroundCommandHandler, UIApplication.shared.applicationState != .active {
            backgroundCommandHandler(command)
            return
        }
        commandCount += 1
        self.command = ReceivedWatchCommand(id: commandCount, command: command)
    }

    // MARK: - Settings

    /// The iPhone's setup or unlocks changed (or the app just opened): share
    /// them with the watch. `current.changedAt` is ignored; a new choice is
    /// stamped now, and an unchanged one keeps its time so it can't override
    /// a newer change made on the watch.
    func phoneSettingsChanged(_ current: SyncedSettings) {
        var next = current
        if let shared, current.sameChoices(as: shared) {
            next.changedAt = shared.changedAt
        } else {
            // The first time, the iPhone's long-standing setup should beat the
            // watch's (which predates sync), but not any change made since.
            next.changedAt = shared == nil ? Date(timeIntervalSince1970: 0) : .now
        }
        guard next != shared else { return }
        shared = next
        sendSettings()
    }

    private func sendSettings() {
        guard let shared, WCSession.isSupported(), WCSession.default.activationState == .activated,
              WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        do {
            try WCSession.default.updateApplicationContext([SyncedSettings.contextKey: shared.encoded()])
        } catch {
            log.error("Couldn't share settings with the watch: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// The watch sent its setup: take any newer choices into Settings.
    private func receivedSettings(_ remote: SyncedSettings) {
        let base = shared ?? SyncedSettings()
        let merged = base.merged(withRemote: remote, remoteIsPhone: false)
        guard !merged.sameChoices(as: base) || merged.changedAt != base.changedAt else { return }
        shared = merged
        guard let context = container?.mainContext,
              let settings = try? context.fetch(FetchDescriptor<UserSettings>()).first else { return }
        settings.difficultyRaw = merged.difficulty.rawValue
        settings.useHalfDeck = merged.useHalfDeck
        settings.hasWeights = merged.hasWeights
        settings.hasPullUpBar = merged.hasPullUpBar
        settings.equippedDeckId = merged.deckId
        settings.disabledExercisesRaw = merged.disabledExercises.map(\.rawValue).sorted().joined(separator: ",")
        do {
            try context.save()
            log.info("Took the watch's settings")
        } catch {
            log.error("Couldn't save the watch's settings: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Workouts finished on the watch

    private func save(_ workout: FinishedWatchWorkout) {
        guard let context = container?.mainContext else { return }
        let id = workout.id
        let existing = (try? context.fetchCount(FetchDescriptor<WorkoutHistory>(predicate: #Predicate { $0.id == id }))) ?? 0
        guard existing == 0 else { return }
        let data = CompletedWorkoutData(session: workout.session, completedAt: workout.completedAt)
        context.insert(WorkoutHistory(data, id: id))
        do {
            try context.save()
            log.info("Saved a watch workout to History: \(data.cardCount, privacy: .public) cards")
        } catch {
            log.error("Couldn't save a watch workout: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func sessionEnded() {
        mirrored = nil
    }
}

extension WatchWorkoutLink: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        guard toState == .ended || toState == .stopped else { return }
        Task { @MainActor in self.sessionEnded() }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        log.error("Mirrored session failed: \(error.localizedDescription, privacy: .public)")
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        Task { @MainActor in data.forEach { self.received($0) } }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didDisconnectFromRemoteDeviceWithError error: (any Error)?) {
        log.info("Watch disconnected: \(error?.localizedDescription ?? "no error", privacy: .public)")
        Task { @MainActor in self.sessionEnded() }
    }
}

extension WatchWorkoutLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: (any Error)?) {
        guard activationState == .activated else { return }
        let data = session.receivedApplicationContext[SyncedSettings.contextKey] as? Data
        Task { @MainActor in
            if let data, let remote = try? SyncedSettings.decode(data) { self.receivedSettings(remote) }
            self.sendSettings()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[SyncedSettings.contextKey] as? Data,
              let remote = try? SyncedSettings.decode(data) else { return }
        Task { @MainActor in self.receivedSettings(remote) }
    }

    /// The watch app was just installed or the watch was paired: send the setup.
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.sendSettings() }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo[FinishedWatchWorkout.userInfoKey] as? Data,
              let workout = try? FinishedWatchWorkout.decode(data) else { return }
        Task { @MainActor in self.save(workout) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in self.received(messageData) }
    }

    /// The watch app came within reach (e.g. it just launched): catch it up.
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in self.catchUpWatch() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}

/// Carries a HealthKit object across to the main actor. HealthKit hands the
/// mirrored session over on its own queue; it's only used on the main actor.
private struct UncheckedSendable<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}

// MARK: - Background relay


/// Keeps a workout the watch is following moving while the iPhone app is
/// in the background (screen locked, phone in a pocket).
///
/// Normally the workout screen runs the watch's commands and the timed steps
/// between states (a card flying off, the hold countdown starting), and the
/// root view sends each change to the watch. All of that hangs off SwiftUI
/// `onChange`, which doesn't run while the app is in the background, so the
/// watch's taps went nowhere and the deck sat on its current card until the
/// iPhone was opened again.
///
/// While the app isn't active this does the same work without the view: it
/// takes the watch's commands, advances the timed steps, and sends each new
/// state to the watch. In the foreground it stays out of the way. The steps
/// it advances are guarded, so if the view runs one as well it's a no-op.
@MainActor
final class WatchWorkoutRelay {
    private let link: WatchWorkoutLink
    private weak var coordinator: WorkoutCoordinator?
    private var lastState: WorkoutState = .idle

    /// Records a workout ended early in History; true when an entry was written.
    var onEndEarly: @MainActor () -> Bool = { false }
    /// Records a finished workout and shows the completion screen.
    var onWorkoutComplete: @MainActor () -> Void = {}

    /// Matches the workout screen's card fly-off and return-to-deck timings.
    private static let completeDelay: Duration = .milliseconds(350)
    private static let skipDelay: Duration = .milliseconds(600)

    init(link: WatchWorkoutLink) {
        self.link = link
        link.backgroundCommandHandler = { [weak self] command in
            self?.handle(command)
        }
    }

    private var isInBackground: Bool {
        UIApplication.shared.applicationState != .active
    }

    /// Follows `coordinator` from now on (it's replaced after each workout).
    func attach(_ coordinator: WorkoutCoordinator) {
        guard coordinator !== self.coordinator else { return }
        self.coordinator = coordinator
        lastState = coordinator.state
        observe(coordinator)
    }

    private func observe(_ coordinator: WorkoutCoordinator) {
        withObservationTracking {
            _ = coordinator.state
            _ = coordinator.isHoldPausedInPlace
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                // A replaced coordinator stops being followed.
                guard let self, self.coordinator === coordinator else { return }
                self.changed(coordinator)
                self.observe(coordinator)
            }
        }
    }

    private func changed(_ coordinator: WorkoutCoordinator) {
        let old = lastState
        let new = coordinator.state
        lastState = new
        guard isInBackground, !coordinator.isTutorial else { return }

        // Keep the watch in step (the root view does this in the foreground).
        if new == .idle {
            if old != .idle { link.workoutEnded() }
            return
        }
        link.update(coordinator.remoteSnapshot)

        guard new != old else { return }
        switch new {
        case .holdStarting:
            coordinator.send(.startHold)
        case .cardCompleting:
            advance(coordinator, from: new, after: Self.completeDelay)
        case .cardSkipping:
            advance(coordinator, from: new, after: Self.skipDelay)
        case .workoutComplete:
            onWorkoutComplete()
        default:
            break
        }
    }

    private func advance(_ coordinator: WorkoutCoordinator, from expected: WorkoutState, after delay: Duration) {
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            // Skip it if the view (back in the foreground) already moved on.
            guard coordinator.state == expected else { return }
            coordinator.send(.advanceComplete)
        }
    }

    /// A command from the watch that arrived while the app was in the
    /// background. Mirrors the workout screen's handling, without the animation.
    private func handle(_ command: RemoteWorkoutCommand) {
        guard let coordinator else { return }
        switch (command, coordinator.state) {
        case (.flip, .cardFaceDown):
            coordinator.send(.flipCard)
        case (.done, .cardFaceUp(_, let prescription)):
            coordinator.send(prescription.isHold ? .startHold : .markDone(reps: nil, holdSeconds: nil))
        case (.done, .holdComplete):
            coordinator.send(.advanceComplete)
        case (.skip, .holding(_, let start, let duration)):
            let held = min(duration, Int(Date().timeIntervalSince(start)))
            coordinator.send(.markDone(reps: nil, holdSeconds: held))
        case (.skip, .cardFaceUp):
            coordinator.send(.skip)
        case (.pause, _):
            if coordinator.isHoldPausedInPlace {
                coordinator.showFullPause()
            } else {
                coordinator.send(.pause)
            }
        case (.resume, _):
            coordinator.send(.resume)
        case (.toggleHoldPause, _):
            coordinator.toggleHoldPause()
        case (.end, _):
            let recorded = onEndEarly()
            coordinator.endEarly(discardSession: recorded)
        default:
            break  // Out of date: the card moved on before the command arrived.
        }
    }
}
