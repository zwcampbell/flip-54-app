import Foundation
import Testing
import Flip54Core
@testable import Flip54WorkoutEngine

@Suite("WorkoutState")
struct WorkoutStateTests {
    @Test("Codable round-trip for all non-associated cases")
    func codableSimpleCases() throws {
        let cases: [WorkoutState] = [
            .idle, .shuffling, .cardFaceDown, .workoutComplete
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for state in cases {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(WorkoutState.self, from: data)
            #expect(decoded == state)
        }
    }

    @Test("Codable round-trip for cardFaceUp")
    func codableCardFaceUp() throws {
        let state = WorkoutState.cardFaceUp(
            card: .standard(suit: .hearts, rank: .seven),
            prescription: .reps(exercise: .pushUp, count: 7)
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(WorkoutState.self, from: data)
        #expect(decoded == state)
    }

    @Test("Codable round-trip for paused")
    func codablePaused() throws {
        let state = WorkoutState.paused(previous: .cardFaceDown)
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(WorkoutState.self, from: data)
        #expect(decoded == state)
    }

    @Test("Equality of distinct states")
    func equality() {
        #expect(WorkoutState.idle == .idle)
        #expect(WorkoutState.cardFaceDown != .workoutComplete)
    }
}
