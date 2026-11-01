import Foundation
import HealthKit
import Observation
import WatchConnectivity
import os
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
@MainActor
@Observable
final class WatchWorkoutLink: NSObject {
    /// Latest command from the watch.
    private(set) var command: ReceivedWatchCommand?

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var mirrored: HKWorkoutSession?
    @ObservationIgnored private var latest: RemoteWorkoutSnapshot?
    @ObservationIgnored private var commandCount = 0

    override init() {
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
            session.sendMessageData(data, replyHandler: nil) { error in
                log.error("Couldn't message the watch: \(error.localizedDescription, privacy: .public)")
            }
            return
        }
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
        guard case .command(let command) = try? RemoteWorkoutMessage.decode(data) else { return }
        commandCount += 1
        self.command = ReceivedWatchCommand(id: commandCount, command: command)
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
                             error: (any Error)?) {}

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
