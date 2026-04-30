public enum Rank: String, Codable, CaseIterable, Hashable, Sendable {
    case two, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    /// Numeric value for pip-as-reps. Returns nil for face cards and Aces.
    public var pipValue: Int? {
        switch self {
        case .two:   return 2
        case .three: return 3
        case .four:  return 4
        case .five:  return 5
        case .six:   return 6
        case .seven: return 7
        case .eight: return 8
        case .nine:  return 9
        case .ten:   return 10
        case .jack, .queen, .king, .ace: return nil
        }
    }

    public var isFace: Bool {
        self == .jack || self == .queen || self == .king
    }

    public var displaySymbol: String {
        switch self {
        case .two:   return "2"
        case .three: return "3"
        case .four:  return "4"
        case .five:  return "5"
        case .six:   return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine:  return "9"
        case .ten:   return "10"
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        case .ace:   return "A"
        }
    }
}
