public enum Exercise: String, Codable, Hashable, Sendable {
    // Lower body
    case bodyweightSquat
    case lunge
    case jumpingSquat
    case gobletSquat

    // Upper body
    case pushUp
    case hinduPushUp
    case pullUp
    case bicepCurl
    case shoulderPress
    case tricepExtension

    // Total body
    case burpee
    case mountainClimber
    case thruster

    // Core
    case sitUp
    case russianTwist
    case weightedSitUp

    // Conditioning
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
        case .bodyweightSquat: return "Body-weight Squats"
        case .lunge:           return "Lunges"
        case .jumpingSquat:    return "Jumping Squats"
        case .gobletSquat:     return "Goblet Squats"
        case .pushUp:          return "Push-ups"
        case .hinduPushUp:     return "Hindu Push-ups"
        case .pullUp:          return "Pull-ups"
        case .bicepCurl:       return "Bicep Curls"
        case .shoulderPress:   return "Shoulder Press"
        case .tricepExtension: return "Tricep Extensions"
        case .burpee:          return "Burpees"
        case .mountainClimber: return "Mountain Climbers"
        case .thruster:        return "Thrusters"
        case .sitUp:           return "Sit-ups"
        case .russianTwist:    return "Russian Twists"
        case .weightedSitUp:   return "Weighted Sit-ups"
        case .jumpingJacks:    return "Jumping Jacks"
        case .pushUpHold:      return "Push-up Hold"
        case .deadHang:        return "Dead Hang"
        case .hollowBodyHold:  return "Hollow Body Hold"
        case .wallSit:         return "Wall Sit"
        case .plank:           return "Plank"
        }
    }
}
