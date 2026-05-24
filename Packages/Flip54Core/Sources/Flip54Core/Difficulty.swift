public enum Difficulty: String, Codable, CaseIterable, Hashable, Sendable {
    case beginner, standard, advanced

    public var multiplier: Double {
        switch self {
        case .beginner: return 0.5
        case .standard: return 1.0
        case .advanced: return 2.0
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
