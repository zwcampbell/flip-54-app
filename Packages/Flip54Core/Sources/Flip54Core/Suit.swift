public enum Suit: String, Codable, CaseIterable, Hashable, Sendable {
    case hearts, spades, clubs, diamonds

    public var color: SuitColor {
        switch self {
        case .hearts, .diamonds: .red
        case .spades, .clubs:   .black
        }
    }

    public var bodyFocusLabel: String {
        switch self {
        case .hearts:   return "Lower Body"
        case .spades:   return "Upper Body"
        case .clubs:    return "Total Body"
        case .diamonds: return "Core"
        }
    }

    public var suitCharacter: String {
        switch self {
        case .hearts:   return "♥"
        case .spades:   return "♠"
        case .clubs:    return "♣"
        case .diamonds: return "♦"
        }
    }
}

public enum SuitColor: String, Codable, Sendable {
    case red, black
}
