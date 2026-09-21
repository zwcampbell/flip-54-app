import Foundation
import SwiftData
import Flip54Core

@Model
public final class UserSettings {
    public var hasWeights: Bool
    public var hasPullUpBar: Bool
    public var hasYogaMat: Bool
    public var difficultyRaw: String
    public var equippedDeckId: String
    public var useHalfDeck: Bool = false
    /// Comma-separated Exercise rawValues the user has disabled, e.g. "pushUp,burpee".
    /// Lives alongside the other workout-configuration fields here (rather than
    /// in UserDefaults) since it's exactly the same kind of data as equipment/
    /// difficulty/deck: per-user workout config read by both PreWorkoutView
    /// and SettingsView.
    public var disabledExercisesRaw: String = ""

    public init(
        hasWeights: Bool = false,
        hasPullUpBar: Bool = false,
        hasYogaMat: Bool = false,
        difficulty: Difficulty = .standard,
        equippedDeckId: String = "standard",
        useHalfDeck: Bool = false
    ) {
        self.hasWeights = hasWeights
        self.hasPullUpBar = hasPullUpBar
        self.hasYogaMat = hasYogaMat
        self.difficultyRaw = difficulty.rawValue
        self.equippedDeckId = equippedDeckId
        self.useHalfDeck = useHalfDeck
    }

    public var equipment: Equipment {
        Equipment(hasWeights: hasWeights, hasPullUpBar: hasPullUpBar, hasYogaMat: hasYogaMat)
    }

    public var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .standard
    }

    public var disabledExercises: Set<Exercise> {
        Set(disabledExercisesRaw.split(separator: ",").compactMap { Exercise(rawValue: String($0)) })
    }
}
