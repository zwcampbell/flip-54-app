import Foundation
import Flip54Core
import Flip54Storage

// MARK: - Completed workout data snapshot

struct CompletedWorkoutData {
    let completedAt: Date
    let duration: TimeInterval
    let deckId: String
    let difficulty: Difficulty
    let totalReps: Int
    let holdSecondsCompleted: Int
    let cardCount: Int
    let skipCount: Int
    let repsBySuit: [Suit: Int]
    let jumpingJacks: Int
    let exerciseReps: [Exercise: Int]

    init(session: ActiveSession, completedAt: Date) {
        self.completedAt = completedAt
        let elapsed = completedAt.timeIntervalSince(session.startedAt) - session.totalPausedDuration
        self.duration = max(0, elapsed)
        self.deckId = session.deckId
        self.difficulty = session.difficulty
        self.totalReps = session.totalRepsCompleted
        self.holdSecondsCompleted = session.holdSecondsCompleted
        self.cardCount = session.cardsCompleted
        self.skipCount = session.skipCount
        self.repsBySuit = session.repsBySuit
        let suitReps = session.repsBySuit.values.reduce(0, +)
        self.jumpingJacks = session.totalRepsCompleted - suitReps
        self.exerciseReps = session.exerciseReps
    }
}

extension WorkoutHistory {
    /// A History entry for a finished workout. Pass `id` to make saving the
    /// same workout twice (a watch record delivered again) a no-op.
    convenience init(_ data: CompletedWorkoutData, id: UUID = UUID()) {
        self.init(
            id: id,
            completedAt: data.completedAt,
            duration: data.duration,
            deckId: data.deckId,
            difficulty: data.difficulty,
            totalReps: data.totalReps,
            holdSecondsCompleted: data.holdSecondsCompleted,
            cardCount: data.cardCount,
            skipCount: data.skipCount,
            repsBySuit: data.repsBySuit,
            jumpingJacks: data.jumpingJacks,
            exerciseReps: data.exerciseReps
        )
    }
}
