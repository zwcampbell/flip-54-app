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

    /// 27-card challenge deck: drops every 2..7 and one of the 8s/jokers,
    /// keeping all face cards, Aces, and high pip values across every suit.
    /// Composition: 4×{A,K,Q,J,10,9} (24) + 2×8s (♥, ♠) + 1 joker = 27.
    public static func halfDeck() -> [Card] {
        var deck: [Card] = []
        let topRanks: [Rank] = [.ace, .king, .queen, .jack, .ten, .nine]
        for suit in Suit.allCases {
            for rank in topRanks {
                deck.append(.standard(suit: suit, rank: rank))
            }
        }
        deck.append(.standard(suit: .hearts, rank: .eight))
        deck.append(.standard(suit: .spades, rank: .eight))
        deck.append(.joker(variant: .red))
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
