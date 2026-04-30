public enum Suit: String, Codable, CaseIterable, Hashable, Sendable {
    case hearts, spades, clubs, diamonds

    public var color: SuitColor {
        switch self {
        case .hearts, .diamonds: .red
        case .spades, .clubs:   .black
        }
    }
}

public enum SuitColor: String, Codable, Sendable {
    case red, black
}
