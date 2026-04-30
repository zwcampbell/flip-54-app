public enum Difficulty: String, Codable, CaseIterable, Hashable, Sendable {
    case beginner, standard, advanced

    public var multiplier: Double {
        switch self {
        case .beginner: return 0.75
        case .standard: return 1.0
        case .advanced: return 1.25
        }
    }

    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .standard: return "Standard"
        case .advanced: return "Advanced"
        }
    }
}
