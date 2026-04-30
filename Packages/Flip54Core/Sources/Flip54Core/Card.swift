public enum Card: Codable, Hashable, Sendable {
    case standard(suit: Suit, rank: Rank)
    case joker(variant: JokerVariant)

    public static func standardDeck() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(.standard(suit: suit, rank: rank))
            }
        }
        deck.append(.joker(variant: .red))
        deck.append(.joker(variant: .black))
        return deck
    }

    public var isAce: Bool {
        if case .standard(_, .ace) = self { return true }
        return false
    }

    public var isJoker: Bool {
        if case .joker = self { return true }
        return false
    }

    public var isFaceCard: Bool {
        if case .standard(_, let rank) = self { return rank.isFace }
        return false
    }

    public var suit: Suit? {
        if case .standard(let suit, _) = self { return suit }
        return nil
    }
}

public enum JokerVariant: String, Codable, Hashable, Sendable {
    case red, black
}
