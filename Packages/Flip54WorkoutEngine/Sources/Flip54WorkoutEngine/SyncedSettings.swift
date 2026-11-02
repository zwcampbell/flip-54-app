import Foundation
import Flip54Core

/// Workout setup shared between the iPhone and the watch, sent as each
/// side's WatchConnectivity application context.
///
/// The setup choices go both ways and the newer `changedAt` wins, so a
/// change on either device shows up on the other. The deck unlocks only come
/// from the iPhone, which keeps History.
public struct SyncedSettings: Codable, Equatable, Sendable {
    /// The application-context key the settings travel under.
    public static let contextKey = "flip54.settings"

    public var difficulty: Difficulty
    public var useHalfDeck: Bool
    public var hasWeights: Bool
    public var hasPullUpBar: Bool
    /// The card style ("standard", "midas", …).
    public var deckId: String
    public var disabledExercises: Set<Exercise>
    /// Decks unlocked on the iPhone. Only the iPhone sets these.
    public var unlockedDeckIds: Set<String>
    /// Workouts still needed to unlock each locked deck. Only the iPhone sets these.
    public var workoutsToUnlock: [String: Int]
    /// When the setup choices were last changed, on either device.
    public var changedAt: Date

    public init(difficulty: Difficulty = .standard, useHalfDeck: Bool = false,
                hasWeights: Bool = false, hasPullUpBar: Bool = false,
                deckId: String = "standard", disabledExercises: Set<Exercise> = [],
                unlockedDeckIds: Set<String> = ["standard"], workoutsToUnlock: [String: Int] = [:],
                changedAt: Date = .distantPast) {
        self.difficulty = difficulty
        self.useHalfDeck = useHalfDeck
        self.hasWeights = hasWeights
        self.hasPullUpBar = hasPullUpBar
        self.deckId = deckId
        self.disabledExercises = disabledExercises
        self.unlockedDeckIds = unlockedDeckIds
        self.workoutsToUnlock = workoutsToUnlock
        self.changedAt = changedAt
    }

    /// True when both have the same setup choices, whatever their unlocks or times.
    public func sameChoices(as other: SyncedSettings) -> Bool {
        difficulty == other.difficulty && useHalfDeck == other.useHalfDeck
            && hasWeights == other.hasWeights && hasPullUpBar == other.hasPullUpBar
            && deckId == other.deckId && disabledExercises == other.disabledExercises
    }

    /// Merges what the other device sent into these settings: its choices
    /// when they're newer, and, from the iPhone, its unlocks. A card style
    /// that isn't unlocked falls back to the standard deck.
    public func merged(withRemote remote: SyncedSettings, remoteIsPhone: Bool) -> SyncedSettings {
        var result = self
        if remote.changedAt > changedAt {
            result.difficulty = remote.difficulty
            result.useHalfDeck = remote.useHalfDeck
            result.hasWeights = remote.hasWeights
            result.hasPullUpBar = remote.hasPullUpBar
            result.deckId = remote.deckId
            result.disabledExercises = remote.disabledExercises
            result.changedAt = remote.changedAt
        }
        if remoteIsPhone {
            result.unlockedDeckIds = remote.unlockedDeckIds
            result.workoutsToUnlock = remote.workoutsToUnlock
        }
        if !result.unlockedDeckIds.contains(result.deckId) {
            result.deckId = "standard"
        }
        return result
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }

    public static func decode(_ data: Data) throws -> SyncedSettings {
        try JSONDecoder().decode(SyncedSettings.self, from: data)
    }
}
