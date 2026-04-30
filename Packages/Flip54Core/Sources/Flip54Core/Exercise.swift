public enum Exercise: String, Codable, Hashable, Sendable {
    // Movements
    case pushUp
    case pullUp
    case hinduPushUp
    case gobletSquat
    case bodyweightSquat
    case sitUp
    case jumpingJacks

    // Holds (Aces)
    case pushUpHold
    case deadHang
    case hollowBodyHold
    case wallSit
    case plank

    public var isHold: Bool {
        switch self {
        case .pushUpHold, .deadHang, .hollowBodyHold, .wallSit, .plank: return true
        default: return false
        }
    }

    public var displayName: String {
        switch self {
        case .pushUp:          return "Push-ups"
        case .pullUp:          return "Pull-ups"
        case .hinduPushUp:     return "Hindu Push-ups"
        case .gobletSquat:     return "Goblet Squat"
        case .bodyweightSquat: return "Body-weight Squats"
        case .sitUp:           return "Sit-ups"
        case .jumpingJacks:    return "Jumping Jacks"
        case .pushUpHold:      return "Push-up Hold"
        case .deadHang:        return "Dead Hang"
        case .hollowBodyHold:  return "Hollow Body Hold"
        case .wallSit:         return "Wall Sit"
        case .plank:           return "Plank"
        }
    }
}
