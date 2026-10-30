import Foundation
import Testing
import Flip54Core
import Flip54Storage
@testable import Flip54WorkoutEngine

@MainActor
@Suite("WorkoutCoordinator — state transitions")
struct WorkoutCoordinatorTests {

    private func makeCoordinator() -> WorkoutCoordinator {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flip54_coord_test_\(UUID().uuidString).json")
        let store = ActiveSessionStore(url: url)
        let coord = WorkoutCoordinator(store: store)
        coord.configure(equipment: .bodyWeightOnly, difficulty: .standard, deckId: "standard")
        return coord
    }

    @Test("idle → shuffle → shuffling")
    func shuffleTransition() {
        let coord = makeCoordinator()
        #expect(coord.state == .idle)
        coord.send(.shuffle)
        #expect(coord.state == .shuffling)
    }

    @Test("shuffling → shuffleComplete → cardFaceDown")
    func shuffleComplete() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        #expect(coord.state == .cardFaceDown)
    }

    @Test("cardFaceDown → flipCard → cardFaceUp")
    func flipCard() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        coord.send(.flipCard)
        if case .cardFaceUp = coord.state {
            // pass
        } else {
            Issue.record("Expected cardFaceUp, got \(coord.state)")
        }
    }

    @Test("cardFaceUp non-Ace → markDone → cardCompleting")
    func markDoneNonAce() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        coord._seedDrawPile([.standard(suit: .hearts, rank: .seven)])
        coord.send(.flipCard)
        coord.send(.markDone(reps: 7, holdSeconds: nil))
        if case .cardCompleting = coord.state {
            // pass
        } else {
            Issue.record("Expected cardCompleting, got \(coord.state)")
        }
    }

    @Test("cardFaceUp → skip → cardSkipping")
    func skipTransition() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        coord._seedDrawPile([.standard(suit: .hearts, rank: .three), .standard(suit: .hearts, rank: .two)])
        coord.send(.flipCard)
        coord.send(.skip)
        if case .cardSkipping = coord.state {
            // pass
        } else {
            Issue.record("Expected cardSkipping, got \(coord.state)")
        }
    }

    @Test("cardSkipping → advanceComplete → cardFaceDown")
    func skipAdvance() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        coord._seedDrawPile([.standard(suit: .hearts, rank: .three), .standard(suit: .hearts, rank: .two)])
        coord.send(.flipCard)
        coord.send(.skip)
        coord.send(.advanceComplete)
        #expect(coord.state == .cardFaceDown)
    }

    @Test("pause from cardFaceDown → paused, resume → cardFaceDown")
    func pauseResume() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        coord.send(.pause)
        if case .paused(let prev) = coord.state {
            #expect(prev == .cardFaceDown)
        } else {
            Issue.record("Expected paused")
        }
        coord.send(.resume)
        #expect(coord.state == .cardFaceDown)
    }

    @Test("illegal transitions are no-ops")
    func illegalTransitions() {
        let coord = makeCoordinator()
        // markDone from idle should do nothing
        coord.send(.markDone(reps: 5, holdSeconds: nil))
        #expect(coord.state == .idle)
        // flipCard from idle should do nothing
        coord.send(.flipCard)
        #expect(coord.state == .idle)
    }

    @Test("endEarly keeps the session resumable by default")
    func endEarlyKeepsSession() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flip54_coord_test_\(UUID().uuidString).json")
        let store = ActiveSessionStore(url: url)
        let coord = WorkoutCoordinator(store: store)
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        #expect(store.load() != nil)
        coord.endEarly()
        #expect(coord.state == .idle)
        #expect(store.load() != nil)
    }

    @Test("endEarly(discardSession:) clears the persisted session")
    func endEarlyDiscardsSession() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flip54_coord_test_\(UUID().uuidString).json")
        let store = ActiveSessionStore(url: url)
        let coord = WorkoutCoordinator(store: store)
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        #expect(store.load() != nil)
        coord.endEarly(discardSession: true)
        #expect(coord.state == .idle)
        #expect(store.load() == nil)
    }

    @Test("workout completes after all cards marked done")
    func workoutCompletion() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        // Seed single card AFTER session is created
        coord._seedDrawPile([.standard(suit: .hearts, rank: .two)])
        coord.send(.flipCard)
        coord.send(.markDone(reps: 2, holdSeconds: nil))
        coord.send(.advanceComplete)
        #expect(coord.state == .workoutComplete)
    }

    @Test("tutorial deck plays in documented order, starting with the 7 of hearts")
    func tutorialDeckOrder() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flip54_coord_test_\(UUID().uuidString).json")
        let coord = WorkoutCoordinator(store: ActiveSessionStore(url: url))
        coord.configureTutorial(equipment: .bodyWeightOnly, difficulty: .standard)
        coord.send(.shuffle)
        coord.send(.shuffleComplete)

        let expected: [Card] = [
            .standard(suit: .hearts,   rank: .seven),
            .standard(suit: .spades,   rank: .king),
            .standard(suit: .clubs,    rank: .ace),
            .standard(suit: .diamonds, rank: .five),
            .joker(variant: .red),
        ]
        var flipped: [Card] = []
        for _ in expected {
            coord.send(.flipCard)
            guard case .cardFaceUp(let card, _) = coord.state else {
                Issue.record("Expected cardFaceUp, got \(coord.state)")
                return
            }
            flipped.append(card)
            if card.isAce {
                coord.send(.skip)
            } else {
                coord.send(.markDone(reps: 1, holdSeconds: nil))
            }
            coord.send(.advanceComplete)
        }
        #expect(flipped == expected)
    }

    /// Flips a lone Ace of clubs and starts its hold, returning the hold
    /// length the coordinator committed to.
    private func startAceHold(_ coord: WorkoutCoordinator) -> Int? {
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        coord._seedDrawPile([.standard(suit: .clubs, rank: .ace)])
        coord.send(.flipCard)
        coord.send(.startHold)   // cardFaceUp → holdStarting
        coord.send(.startHold)   // holdStarting → holding
        defer { coord.endEarly() }
        guard case .holding(_, _, let seconds) = coord.state else { return nil }
        return seconds
    }

    @Test("tutorial Ace hold is shortened to 5 seconds")
    func tutorialHoldIsShort() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flip54_coord_test_\(UUID().uuidString).json")
        let coord = WorkoutCoordinator(store: ActiveSessionStore(url: url))
        coord.configureTutorial(equipment: .bodyWeightOnly, difficulty: .standard)
        #expect(startAceHold(coord) == WorkoutCoordinator.tutorialHoldSeconds)
        #expect(WorkoutCoordinator.tutorialHoldSeconds == 5)
    }

    @Test("a hold that runs out counts its full length")
    func expiredHoldCountsFullLength() {
        let coord = makeCoordinator()
        coord.send(.shuffle)
        coord.send(.shuffleComplete)
        coord._seedDrawPile([.standard(suit: .clubs, rank: .ace)])
        coord.send(.flipCard)
        coord.send(.startHold)
        coord.send(.startHold)
        defer { coord.endEarly() }
        guard case .holding(_, _, let duration) = coord.state else {
            Issue.record("expected .holding, got \(coord.state)")
            return
        }
        coord.send(.holdTimerExpired)
        guard case .holdComplete(_, let held, let completedFully) = coord.state else {
            Issue.record("expected .holdComplete, got \(coord.state)")
            return
        }
        #expect(held == duration)
        #expect(completedFully)
        #expect(coord.session?.holdSecondsCompleted == duration)
    }

    @Test("real workout Ace hold keeps its prescribed length")
    func realHoldIsUnchanged() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flip54_coord_test_\(UUID().uuidString).json")
        let coord = WorkoutCoordinator(store: ActiveSessionStore(url: url))
        coord.configure(equipment: .bodyWeightOnly, difficulty: .standard, deckId: "standard")
        #expect(startAceHold(coord) == 60)
    }
}
