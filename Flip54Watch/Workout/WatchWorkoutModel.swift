import Foundation
import Observation
import WatchKit
import Flip54Core
import Flip54Storage
import Flip54WorkoutEngine

/// Workout setup chosen on the watch. Kept in the watch's own UserDefaults
/// until phone ↔ watch settings sync lands.
@MainActor
@Observable
final class WatchSettings {
    var difficulty: Difficulty { didSet { defaults.set(difficulty.rawValue, forKey: Key.difficulty) } }
    var useHalfDeck: Bool { didSet { defaults.set(useHalfDeck, forKey: Key.halfDeck) } }
    var hasWeights: Bool { didSet { defaults.set(hasWeights, forKey: Key.weights) } }
    var hasPullUpBar: Bool { didSet { defaults.set(hasPullUpBar, forKey: Key.pullUpBar) } }

    private let defaults: UserDefaults

    private enum Key {
        static let difficulty = "watch.difficulty"
        static let halfDeck = "watch.useHalfDeck"
        static let weights = "watch.hasWeights"
        static let pullUpBar = "watch.hasPullUpBar"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        difficulty = Difficulty(rawValue: defaults.string(forKey: Key.difficulty) ?? "") ?? .standard
        useHalfDeck = defaults.bool(forKey: Key.halfDeck)
        hasWeights = defaults.bool(forKey: Key.weights)
        hasPullUpBar = defaults.bool(forKey: Key.pullUpBar)
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
    /// Set when a workout finishes or is ended with cards done; cleared by Done.
    private(set) var summary: WatchWorkoutSummary?
    /// True while an Ace hold is paused by tapping its timer. The hold stays on
    /// the card page instead of the Paused screen.
    private(set) var isHoldPausedByTap = false

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
    }

    var state: WorkoutState { coordinator.state }
    var session: ActiveSession? { coordinator.session }

    // MARK: - Actions

    func start() {
        summary = nil
        coordinator.configure(
            equipment: settings.equipment,
            difficulty: settings.difficulty,
            deckId: "standard",
            useHalfDeck: settings.useHalfDeck
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
        Task { await recorder.start(at: startedAt) }
        play(.start)
    }

    func flip() {
        coordinator.send(.flipCard)
        play(.click)
    }

    func done() {
        switch state {
        case .cardFaceUp(_, let prescription) where prescription.isHold:
            // No 3-2-1 countdown: go straight from the Ace to the running hold.
            coordinator.send(.startHold)
            play(.start)
        case .cardFaceUp:
            coordinator.send(.markDone(reps: nil, holdSeconds: nil))
            play(.success)
        case .holdComplete:
            coordinator.send(.advanceComplete)
        default:
            break
        }
    }

    /// Skip puts the card back at the bottom of the deck, except during a hold,
    /// where it ends the hold early and credits the seconds held.
    func skip() {
        if case .holding(_, let start, let duration) = state {
            let held = min(duration, Int(Date().timeIntervalSince(start)))
            coordinator.send(.markDone(reps: nil, holdSeconds: held))
        } else {
            coordinator.send(.skip)
        }
        play(.directionDown)
    }

    /// Tapping the hold timer pauses the hold (and the workout) in place, and
    /// tapping again resumes it.
    func toggleHoldPause() {
        if isHoldPausedByTap {
            resume()
        } else if case .holding = state {
            pause()
            isHoldPausedByTap = true
        }
    }

    func pause() {
        // Pause while a hold is tap-paused: move it to the full Paused screen.
        if isHoldPausedByTap {
            isHoldPausedByTap = false
            return
        }
        coordinator.send(.pause)
        recorder.pause()
        play(.stop)
    }

    func resume() {
        isHoldPausedByTap = false
        coordinator.send(.resume)
        recorder.resume()
        play(.start)
    }

    /// Ends the workout now. Shows a summary when at least one card was done,
    /// and saves to Health only then; an untouched deck is discarded.
    func end() {
        isHoldPausedByTap = false
        if let session {
            let hasProgress = session.cardsCompleted > 0
            if hasProgress {
                summary = WatchWorkoutSummary(session: session, endedEarly: true)
            }
            finishRecording(session, save: hasProgress)
        }
        coordinator.endEarly(discardSession: true)
        play(.stop)
    }

    /// watchOS paused or resumed the Health session itself (e.g. from the
    /// system workout controls): keep the deck in step.
    private func sessionPausedExternally(_ paused: Bool) {
        if paused, !isPaused {
            coordinator.send(.pause)
        } else if !paused, isPaused {
            isHoldPausedByTap = false
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

    // MARK: - Engine follow-ups

    /// Call on every state change. Advances through the states the engine
    /// expects the UI to time (shuffle, card leaving) and plays haptics.
    func stateChanged(to new: WorkoutState) {
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
