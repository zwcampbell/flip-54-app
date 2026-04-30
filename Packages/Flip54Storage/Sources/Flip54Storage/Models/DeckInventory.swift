import Foundation
import SwiftData

@Model
public final class DeckInventory {
    @Attribute(.unique) public var deckId: String
    public var unlockedAt: Date?
    public var equipped: Bool

    public init(deckId: String, unlockedAt: Date? = nil, equipped: Bool = false) {
        self.deckId = deckId
        self.unlockedAt = unlockedAt
        self.equipped = equipped
    }

    public var isUnlocked: Bool { unlockedAt != nil }
}
