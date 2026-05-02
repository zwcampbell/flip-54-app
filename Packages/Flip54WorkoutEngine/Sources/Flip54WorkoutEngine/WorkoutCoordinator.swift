import Foundation
import Flip54Core
import Flip54Storage

/// Owns the workout state machine. All mutations go through `send(_:)`.
/// Persists the active session on every state change.
@MainActor
@Observable
public final class WorkoutCoordinator {
    public private(set) var state: WorkoutState = .idle
    public private(set) var session: ActiveSession?
    /// True when running a tutorial flip — coordinator won't persist session and caller skips history save.
    public private(set) var isTutorial: Bool = false

    private let store: ActiveSessionStore
    private let holdTimer: HoldTimer

    public init(store: ActiveSessionStore = ActiveSessionStore()) {
        self.store = store
        self.holdTimer = HoldTimer()
        self.holdTimer.onExpired = { [weak self] in
            Task { @MainActor [weak self] in
                self?.send(.holdTimerExpired)
            }
        }
    }

    // MARK: - Public API

    public func send(_ event: WorkoutEvent) {
        let next = transition(state: state, event: event)
        guard next != state else { return }
        applyTransition(from: state, to: next, event: event)
        state = next
    }

    // MARK: - Transition table

    private func transition(state: WorkoutState, event: WorkoutEvent) -> WorkoutState {
        switch (state, event) {

        case (.idle, .shuffle):
            return .shuffling

        case (.shuffling, .shuffleComplete):
            return .cardFaceDown

        case (.cardFaceDown, .flipCard):
            guard var s = session, !s.drawPile.isEmpty else { return state }
            s.flipNextCard()
            session = s
            guard let card = s.currentCard else { return state }
            let p = prescription(for: card, equipment: s.equipment, difficulty: s.difficulty)
            return .cardFaceUp(card: card, prescription: p)

        case (.cardFaceUp(let card, _), .startHold) where card.isAce:
            return .holdStarting(card: card)

        case (.holdStarting(let card), .startHold):
            guard let s = session else { return state }
            let p = prescription(for: card, equipment: s.equipment, difficulty: s.difficulty)
            guard case .hold(_, let secs) = p else { return state }
            return .holding(card: card, startTime: Date(), durationSeconds: secs)

        case (.cardFaceUp(let card, _), .markDone(let reps, let secs)):
            return .cardCompleting(card: card)

        case (.holding(let card, _, _), .markDone(_, let holdSecs)):
            let held = holdSecs ?? 0
            return .holdComplete(card: card, secondsHeld: held, completedFully: false)

        case (.holding(let card, let start, let dur), .holdTimerExpired):
            let held = Int(Date().timeIntervalSince(start))
            return .holdComplete(card: card, secondsHeld: min(held, dur), completedFully: true)

        case (.holdComplete(let card, _, _), .advanceComplete):
            return .cardCompleting(card: card)

        case (.cardFaceUp(let card, _), .skip),
             (.holdStarting(let card), .skip),
             (.holding(let card, _, _), .skip):
            return .cardSkipping(card: card)

        case (.cardCompleting, .advanceComplete):
            guard let s = session else { return .workoutComplete }
            return s.isComplete ? .workoutComplete : .cardFaceDown

        case (.cardSkipping, .advanceComplete):
            return .cardFaceDown

        case (_, .pause) where !isPaused(state):
            return .paused(previous: state)

        case (.paused(let prev), .resume):
            return prev

        default:
            return state
        }
    }

    // MARK: - Side effects

    private func applyTransition(from: WorkoutState, to: WorkoutState, event: WorkoutEvent) {
        switch to {
        case .shuffling:
            startNewSession()

        case .holding(_, let start, let dur):
            var elapsed: TimeInterval = 0
            if let s = session { elapsed = s.holdElapsed }
            holdTimer.start(durationSeconds: dur, alreadyElapsed: elapsed)
            session?.startHold(at: start)

        case .holdComplete(let card, let secs, _):
            holdTimer.cancel()
            if card.isAce {
                session?.completeCurrentCard(reps: nil, holdSeconds: secs)
            }

        case .cardCompleting(let card):
            if case .cardFaceUp(_, let p) = from, case .reps(_, let count) = p {
                session?.completeCurrentCard(reps: count, holdSeconds: nil)
            }
            persistSession()

        case .cardSkipping:
            holdTimer.cancel()
            session?.skipCurrentCard()
            persistSession()

        case .workoutComplete:
            store.clear()

        case .paused(let prev):
            session?.pause(at: Date())
            holdTimer.cancel()
            persistSession()

        case .cardFaceDown:
            if case .paused(_) = from {
                session?.resume(at: Date())
                if case .holding(_, let start, let dur) = from {
                    let elapsed = session?.holdElapsed ?? 0
                    holdTimer.start(durationSeconds: dur, alreadyElapsed: elapsed)
                }
            }

        default:
            break
        }
    }

    // MARK: - Helpers

    private func startNewSession() {
        // If a tutorial was just configured, the session is already populated
        // with the abridged tutorial deck and isTutorial=true. Don't clobber it
        // with a fresh standard deck on .shuffle.
        if isTutorial { return }
        var rng = SystemRandomNumberGenerator()
        let equipment = session?.equipment ?? .bodyWeightOnly
        let difficulty = session?.difficulty ?? .standard
        session = ActiveSession.start(
            deck: Card.standardDeck(),
            deckId: session?.deckId ?? "standard",
            equipment: equipment,
            difficulty: difficulty,
            rng: &rng
        )
        persistSession()
    }

    private func persistSession() {
        guard !isTutorial, let s = session else { return }
        try? store.save(s)
    }

    private func isPaused(_ state: WorkoutState) -> Bool {
        if case .paused = state { return true }
        return false
    }

    // MARK: - Resume support

    public func restoreIfNeeded(equipment: Equipment, difficulty: Difficulty, deckId: String) {
        if let saved = store.load(), !saved.isComplete,
           Date().timeIntervalSince(saved.startedAt) < 86400 {
            isTutorial = false  // Persisted sessions are never tutorials.
            session = saved
            state = .cardFaceDown
        } else {
            store.clear()
            session = nil
        }
    }

    public func configure(equipment: Equipment, difficulty: Difficulty, deckId: String) {
        isTutorial = false
        var rng = SystemRandomNumberGenerator()
        session = ActiveSession.start(
            deck: Card.standardDeck(),
            deckId: deckId,
            equipment: equipment,
            difficulty: difficulty,
            rng: &rng
        )
    }

    /// Configure an abridged 5-card tutorial deck: one card from each suit so
    /// the user sees every body-focus, plus a Joker. Card kinds are spread
    /// across the suits (numbered, face, Ace) so each contextual tooltip
    /// fires once. Beginner difficulty. Results are NOT saved to history;
    /// caller checks `isTutorial` before persisting.
    public func configureTutorial(equipment: Equipment, difficulty: Difficulty) {
        isTutorial = true
        let tutorialCards: [Card] = [
            .standard(suit: .hearts,   rank: .seven),  // numbered reps + skip tooltip
            .standard(suit: .spades,   rank: .king),   // face card tooltip
            .standard(suit: .clubs,    rank: .ace),    // Ace hold tooltip
            .standard(suit: .diamonds, rank: .five),   // numbered reps (4th body focus)
            .joker(variant: .red),                     // Joker tooltip
        ]
        var rng = SystemRandomNumberGenerator()
        session = ActiveSession.start(
            deck: tutorialCards,
            deckId: "tutorial",
            equipment: equipment,
            difficulty: .beginner,  // reduced reps for tutorial
            rng: &rng
        )
        // Tutorial deck is already in the desired order — override the shuffled pile
        session?.drawPile = tutorialCards
        session?.currentCard = nil
    }

    /// Exit the in-progress workout and return to `.idle`. For real workouts
    /// the session is left persisted in `ActiveSessionStore` so the home
    /// screen's resume banner can pick it back up. For tutorials the on-disk
    /// store is untouched (tutorials never persist) so any prior real workout
    /// session remains resumable. No history record is written.
    public func endEarly() {
        holdTimer.cancel()
        if !isTutorial, let s = session {
            // Make sure the latest paused session is on disk before we drop
            // our in-memory reference, so the resume banner can find it.
            try? store.save(s)
        }
        session = nil
        isTutorial = false
        state = .idle
    }

    /// Seed a specific draw pile for testing purposes.
    public func _seedDrawPile(_ cards: [Card]) {
        session?.drawPile = cards
        session?.currentCard = nil
    }
}
