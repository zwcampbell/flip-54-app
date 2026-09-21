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
}
