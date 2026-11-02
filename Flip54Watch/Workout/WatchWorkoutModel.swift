import Foundation
import Observation
import WatchKit
import Flip54Core
import Flip54Storage
import Flip54WorkoutEngine

/// Workout setup, shared with the iPhone: a change on either device shows up
/// on the other (the newer change wins), and the iPhone's deck unlocks come
/// along with it. Kept in the watch's UserDefaults between launches.
@MainActor
@Observable
final class WatchSettings {
    /// Everything, as sent to and from the iPhone.
    private(set) var synced: SyncedSettings { didSet { save() } }
    /// Called after a change made on the watch, to send it to the iPhone.
    @ObservationIgnored var onLocalChange: ((SyncedSettings) -> Void)?

    var difficulty: Difficulty {
        get { synced.difficulty }
        set { change { $0.difficulty = newValue } }
    }
    var useHalfDeck: Bool {
        get { synced.useHalfDeck }
        set { change { $0.useHalfDeck = newValue } }
    }
    var hasWeights: Bool {
        get { synced.hasWeights }
        set { change { $0.hasWeights = newValue } }
    }
    var hasPullUpBar: Bool {
        get { synced.hasPullUpBar }
        set { change { $0.hasPullUpBar = newValue } }
    }
    /// Card style: "standard" or an unlocked deck such as "midas".
    var deckId: String {
        get { synced.deckId }
        set { change { $0.deckId = newValue } }
    }
    var disabledExercises: Set<Exercise> { synced.disabledExercises }

    func isUnlocked(_ deckId: String) -> Bool { synced.unlockedDeckIds.contains(deckId) }
    func workoutsToUnlock(_ deckId: String) -> Int? { synced.workoutsToUnlock[deckId] }

    private let defaults: UserDefaults

    private enum Key {
        static let settings = "watch.settings"
        // Before sync, each choice had its own key.
        static let difficulty = "watch.difficulty"
        static let halfDeck = "watch.useHalfDeck"
        static let weights = "watch.hasWeights"
        static let pullUpBar = "watch.hasPullUpBar"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Key.settings), let saved = try? SyncedSettings.decode(data) {
            synced = saved
        } else {
            synced = SyncedSettings(
                difficulty: Difficulty(rawValue: defaults.string(forKey: Key.difficulty) ?? "") ?? .standard,
                useHalfDeck: defaults.bool(forKey: Key.halfDeck),
                hasWeights: defaults.bool(forKey: Key.weights),
                hasPullUpBar: defaults.bool(forKey: Key.pullUpBar)
            )
        }
    }

    /// Takes in what the iPhone sent.
    func apply(fromPhone remote: SyncedSettings) {
        var remote = remote
        #if DEBUG
        // `-unlockMidas YES` at launch treats Midas as unlocked, so its cards
        // can be seen in the simulator without logging three workouts.
        if defaults.bool(forKey: "unlockMidas") { remote.unlockedDeckIds.insert("midas") }
        #endif
        let merged = synced.merged(withRemote: remote, remoteIsPhone: true)
        if merged != synced { synced = merged }
    }

    private func change(_ update: (inout SyncedSettings) -> Void) {
        var next = synced
        update(&next)
        guard !next.sameChoices(as: synced) else { return }
        next.changedAt = .now
        synced = next
        onLocalChange?(next)
    }

    private func save() {
        if let data = try? synced.encoded() { defaults.set(data, forKey: Key.settings) }
    }

    var equipment: Equipment {
        Equipment(hasWeights: hasWeights, hasPullUpBar: hasPullUpBar, hasYogaMat: false)
    }

    var deckName: String { useHalfDeck ? "Half" : "Full" }
    var deckSize: Int { useHalfDeck ? 27 : 54 }

    var equipmentName: String {
        switch (hasWeights, hasPullUpBar) {
        case (false, false): "Body-weight"
        case (true, false):  "Weights"
        case (false, true):  "Pull-up bar"
        case (true, true):   "Weights + bar"
        }
    }
}

/// What the summary screen shows, captured before the engine resets.
struct WatchWorkoutSummary: Equatable {
    let endedEarly: Bool
    let reps: Int
    let cardsCompleted: Int
    let deckSize: Int
    let duration: TimeInterval
    let difficulty: Difficulty
    let halfDeck: Bool

    init(endedEarly: Bool, reps: Int, cardsCompleted: Int, deckSize: Int,
         duration: TimeInterval, difficulty: Difficulty, halfDeck: Bool) {
        self.endedEarly = endedEarly
        self.reps = reps
        self.cardsCompleted = cardsCompleted
        self.deckSize = deckSize
        self.duration = duration
        self.difficulty = difficulty
        self.halfDeck = halfDeck
    }

    init(session: ActiveSession, endedEarly: Bool, at date: Date = .now) {
        self.endedEarly = endedEarly
        reps = session.totalRepsCompleted
        cardsCompleted = session.cardsCompleted
        deckSize = session.deckSize
        duration = WatchWorkoutModel.activeDuration(of: session, at: date)
        difficulty = session.difficulty
        halfDeck = session.deckSize < 54
    }

    var averagePerCard: TimeInterval {
        cardsCompleted > 0 ? duration / Double(cardsCompleted) : 0
    }
}

/// Drives `WorkoutCoordinator` for the watch UI: sends events, runs the short
/// timed steps the engine leaves to the UI (shuffle, card exit), and plays haptics.
@MainActor
@Observable
final class WatchWorkoutModel {
    let coordinator: WorkoutCoordinator
    let settings: WatchSettings
    /// Runs the Apple Health workout session alongside the deck.
    let recorder: WorkoutRecorder
    /// Messages to and from the iPhone while following its workout.
    private let phone = PhoneChannel()
    /// Set when a workout finishes or is ended with cards done; cleared by Done.
    private(set) var summary: WatchWorkoutSummary?
    /// True while the watch follows a workout started on the iPhone: the
    /// iPhone runs the deck and sends snapshots, and the watch's actions go
    /// back to it as commands. The watch still records the Health workout.
    private(set) var isFollowingPhone = false

    /// True while an Ace hold is paused by tapping its timer. The hold stays on
    /// the card page instead of the Paused screen.
    var isHoldPausedByTap: Bool { coordinator.isHoldPausedInPlace }

    /// How long the card-exit and shuffle beats last before the engine advances.
    private static let advanceDelay: Duration = .milliseconds(300)
    private static let shuffleDelay: Duration = .milliseconds(900)

    init(coordinator: WorkoutCoordinator = WorkoutCoordinator(),
         settings: WatchSettings = WatchSettings(),
         recorder: WorkoutRecorder = HealthKitWorkoutRecorder()) {
        self.coordinator = coordinator
        self.settings = settings
        self.recorder = recorder
        coordinator.restoreIfNeeded()
        recorder.onExternalPauseChange = { [weak self] paused in
            self?.sessionPausedExternally(paused)
        }
        recorder.onDataFromPhone = { [weak self] data in
            self?.received(data)
        }
        phone.onData = { [weak self] data in
            self?.received(data)
        }
        phone.onSettings = { [weak self] remote in
            self?.settings.apply(fromPhone: remote)
        }
        settings.onLocalChange = { [weak self] changed in
            self?.phone.sendSettings(changed)
        }
        phone.sendSettings(settings.synced)
    }

    var state: WorkoutState { coordinator.state }
    var session: ActiveSession? { coordinator.session }

    // MARK: - Actions

    func start() {
        summary = nil
        coordinator.configure(
            equipment: settings.equipment,
            difficulty: settings.difficulty,
            deckId: settings.deckId,
            useHalfDeck: settings.useHalfDeck,
            disabledExercises: settings.disabledExercises
        )
        coordinator.send(.shuffle)
        #if DEBUG
        // `-testDeck YES` at launch plays a short deck covering every card kind,
        // so the hold and summary screens can be reached quickly in the simulator.
        if UserDefaults.standard.bool(forKey: "testDeck") {
            // flipNextCard draws from the end, so this plays 7♥, Joker, K♠, A♦.
            coordinator._seedDrawPile([
                .standard(suit: .diamonds, rank: .ace),
                .standard(suit: .spades, rank: .king),
                .joker(variant: .black),
                .standard(suit: .hearts, rank: .seven),
            ])
        }
        #endif
        let startedAt = session?.startedAt ?? .now
        Task { await recorder.start(at: startedAt, mirrorToPhone: false) }
        play(.start)
    }

    /// The iPhone started a workout and launched the watch app for it.
    /// Starts the Health session, mirrored to the iPhone so the deck can flow
    /// over it, and waits for the iPhone's first snapshot.
    func startFollowingPhone() {
        guard !isFollowingPhone else { return }
        summary = nil
        isFollowingPhone = true
        coordinator.mirror(state: .idle, session: nil, isHoldPausedInPlace: false)
        Task { await recorder.start(at: .now, mirrorToPhone: true) }
        play(.start)
    }

    func flip() {
        play(.click)
        if isFollowingPhone { return sendToPhone(.flip) }
        coordinator.send(.flipCard)
    }

    func done() {
        switch state {
        case .cardFaceUp(_, let prescription) where prescription.isHold:
            // No 3-2-1 countdown: go straight from the Ace to the running hold.
            play(.start)
            if isFollowingPhone { return sendToPhone(.done) }
            coordinator.send(.startHold)
        case .cardFaceUp:
            play(.success)
            if isFollowingPhone { return sendToPhone(.done) }
            coordinator.send(.markDone(reps: nil, holdSeconds: nil))
        case .holdComplete:
            if isFollowingPhone { return sendToPhone(.done) }
            coordinator.send(.advanceComplete)
        default:
            break
        }
    }

    /// Skip puts the card back at the bottom of the deck, except during a hold,
    /// where it ends the hold early and credits the seconds held.
    func skip() {
        play(.directionDown)
        if isFollowingPhone { return sendToPhone(.skip) }
        if case .holding(_, let start, let duration) = state {
            let held = min(duration, Int(Date().timeIntervalSince(start)))
            coordinator.send(.markDone(reps: nil, holdSeconds: held))
        } else {
            coordinator.send(.skip)
        }
    }

    /// Tapping the hold timer pauses the hold (and the workout) in place, and
    /// tapping again resumes it.
    func toggleHoldPause() {
        if isFollowingPhone {
            play(isHoldPausedByTap ? .start : .stop)
            return sendToPhone(.toggleHoldPause)
        }
        if isHoldPausedByTap {
            resume()
        } else if case .holding = state {
            coordinator.toggleHoldPause()
            recorder.pause()
            play(.stop)
        }
    }

    func pause() {
        if isFollowingPhone {
            play(.stop)
            return sendToPhone(.pause)
        }
        // Pause while a hold is tap-paused: move it to the full Paused screen.
        if isHoldPausedByTap {
            coordinator.showFullPause()
            return
        }
        coordinator.send(.pause)
        recorder.pause()
        play(.stop)
    }

    func resume() {
        play(.start)
        if isFollowingPhone { return sendToPhone(.resume) }
        coordinator.send(.resume)
        recorder.resume()
    }

    /// Ends the workout now. Shows a summary when at least one card was done,
    /// and saves to Health only then; an untouched deck is discarded.
    func end() {
        if isFollowingPhone {
            sendToPhone(.end)
            stopFollowing(showSummary: true)
            play(.stop)
            return
        }
        if let session {
            let hasProgress = session.cardsCompleted > 0
            if hasProgress {
                summary = WatchWorkoutSummary(session: session, endedEarly: true)
                phone.sendFinished(FinishedWatchWorkout(session: session, completedAt: .now))
            }
            finishRecording(session, save: hasProgress)
        }
        coordinator.endEarly(discardSession: true)
        play(.stop)
    }

    /// watchOS paused or resumed the Health session itself (e.g. from the
    /// system workout controls): keep the deck in step.
    private func sessionPausedExternally(_ paused: Bool) {
        if isFollowingPhone {
            if paused != isPaused { sendToPhone(paused ? .pause : .resume) }
            return
        }
        if paused, !isPaused {
            coordinator.send(.pause)
        } else if !paused, isPaused {
            coordinator.send(.resume)
        }
    }

    private var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    private func finishRecording(_ session: ActiveSession, save: Bool) {
        let totals = WorkoutTotals(reps: session.totalRepsCompleted,
                                   cards: session.cardsCompleted,
                                   deckSize: session.deckSize)
        Task { await recorder.finish(at: .now, save: save, totals: totals) }
    }

    /// Leaves the summary and returns to Start.
    func finish() {
        summary = nil
        if case .workoutComplete = state {
            coordinator.endEarly(discardSession: true)
        }
    }

    // MARK: - Following the iPhone

    private func sendToPhone(_ command: RemoteWorkoutCommand) {
        guard let data = try? RemoteWorkoutMessage.command(command).encoded() else { return }
        // WatchConnectivity when the iPhone app can hear it; otherwise the
        // mirrored Health session, which keeps working with the phone locked.
        if phone.isReachable {
            phone.send(data)
        } else {
            Task { await recorder.send(toPhone: data) }
        }
    }

    private func received(_ data: Data) {
        guard isFollowingPhone, let message = try? RemoteWorkoutMessage.decode(data) else { return }
        switch message {
        case .snapshot(let snapshot):
            let wasPaused = isPaused
            coordinator.mirror(state: snapshot.state, session: snapshot.session,
                               isHoldPausedInPlace: snapshot.isHoldPausedInPlace)
            // Keep the Health session's pauses in step with the deck's.
            if isPaused != wasPaused {
                isPaused ? recorder.pause() : recorder.resume()
            }
        case .ended:
            stopFollowing(showSummary: true)
        case .command, .finished:
            break  // These only go watch → iPhone.
        }
    }

    /// Stops following the iPhone: shows a summary when cards were done,
    /// saves or discards the Health workout, and clears the mirrored deck
    /// (the watch's own saved workout, if any, is left alone).
    private func stopFollowing(showSummary: Bool) {
        guard isFollowingPhone else { return }
        isFollowingPhone = false
        if let session {
            let complete: Bool = if case .workoutComplete = state { true } else { false }
            let hasProgress = session.cardsCompleted > 0
            if showSummary, hasProgress {
                summary = WatchWorkoutSummary(session: session, endedEarly: !complete)
            }
            finishRecording(session, save: hasProgress)
        } else {
            Task { await recorder.finish(at: .now, save: false, totals: WorkoutTotals(reps: 0, cards: 0, deckSize: 0)) }
        }
        coordinator.mirror(state: .idle, session: nil, isHoldPausedInPlace: false)
    }

    // MARK: - Engine follow-ups

    /// Call on every state change. Advances through the states the engine
    /// expects the UI to time (shuffle, card leaving) and plays haptics.
    /// When following the iPhone, the iPhone times those steps itself.
    func stateChanged(to new: WorkoutState) {
        if isFollowingPhone {
            switch new {
            case .holdComplete(_, _, let completedFully):
                if completedFully { play(.success) }
            case .workoutComplete:
                stopFollowing(showSummary: true)
                play(.success)
            default:
                break
            }
            return
        }
        switch new {
        case .shuffling:
            advance(.shuffleComplete, after: Self.shuffleDelay)
        case .holdStarting:
            coordinator.send(.startHold)
        case .cardCompleting, .cardSkipping:
            advance(.advanceComplete, after: Self.advanceDelay)
        case .holdComplete(_, _, let completedFully):
            if completedFully { play(.success) }
        case .workoutComplete:
            if let session {
                summary = WatchWorkoutSummary(session: session, endedEarly: false)
                finishRecording(session, save: true)
                phone.sendFinished(FinishedWatchWorkout(session: session, completedAt: .now))
            }
            play(.success)
        default:
            break
        }
    }

    private func advance(_ event: WorkoutEvent, after delay: Duration) {
        let expected = state
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            // Don't advance if the user paused or ended in the meantime.
            guard let self, self.state == expected else { return }
            self.coordinator.send(event)
        }
    }

    private func play(_ haptic: WKHapticType) {
        WKInterfaceDevice.current().play(haptic)
    }

    // MARK: - Derived values

    /// Time spent working out so far, not counting pauses.
    nonisolated static func activeDuration(of session: ActiveSession, at date: Date) -> TimeInterval {
        var paused = session.totalPausedDuration
        if let pauseStart = session.pauseStartedAt { paused += date.timeIntervalSince(pauseStart) }
        return max(0, date.timeIntervalSince(session.startedAt) - paused)
    }
}
