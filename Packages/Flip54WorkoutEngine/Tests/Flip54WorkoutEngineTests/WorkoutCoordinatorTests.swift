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
}
