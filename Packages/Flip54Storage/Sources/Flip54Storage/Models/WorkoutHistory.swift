import Foundation
import SwiftData
import Flip54Core

@Model
public final class WorkoutHistory {
    @Attribute(.unique) public var id: UUID
    public var completedAt: Date
    public var duration: TimeInterval
    public var deckId: String
    public var difficultyRaw: String
    public var totalReps: Int
    public var holdSecondsCompleted: Int
    public var cardCount: Int
    public var skipCount: Int

    // Per-suit reps (flattened for CloudKit compatibility)
    public var heartsReps: Int
    public var spadesReps: Int
    public var clubsReps: Int
    public var diamondsReps: Int
    public var jumpingJacks: Int
    /// JSON-encoded [Exercise.rawValue: reps]. String keeps CloudKit compatibility.
    public var exerciseRepsJson: String = "{}"

    public var repsByExercise: [Exercise: Int] {
        guard let data = exerciseRepsJson.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
        return dict.reduce(into: [:]) { result, pair in
            if let ex = Exercise(rawValue: pair.key) { result[ex] = pair.value }
        }
    }

    public init(
        id: UUID = UUID(),
        completedAt: Date,
        duration: TimeInterval,
        deckId: String,
        difficulty: Difficulty,
        totalReps: Int,
        holdSecondsCompleted: Int,
        cardCount: Int,
        skipCount: Int,
        repsBySuit: [Suit: Int],
        jumpingJacks: Int,
        exerciseReps: [Exercise: Int] = [:]
    ) {
        self.id = id
        self.completedAt = completedAt
        self.duration = duration
        self.deckId = deckId
        self.difficultyRaw = difficulty.rawValue
        self.totalReps = totalReps
        self.holdSecondsCompleted = holdSecondsCompleted
        self.cardCount = cardCount
        self.skipCount = skipCount
        self.heartsReps = repsBySuit[.hearts] ?? 0
        self.spadesReps = repsBySuit[.spades] ?? 0
        self.clubsReps = repsBySuit[.clubs] ?? 0
        self.diamondsReps = repsBySuit[.diamonds] ?? 0
        self.jumpingJacks = jumpingJacks
        let dict = exerciseReps.reduce(into: [String: Int]()) { $0[$1.key.rawValue] = $1.value }
        self.exerciseRepsJson = (try? String(data: JSONEncoder().encode(dict), encoding: .utf8)) ?? "{}"
    }

    public var repsBySuit: [Suit: Int] {
        [.hearts: heartsReps, .spades: spadesReps, .clubs: clubsReps, .diamonds: diamondsReps]
    }

    public var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .standard
    }
}
