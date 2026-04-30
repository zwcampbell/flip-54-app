public enum Prescription: Codable, Hashable, Sendable {
    case reps(exercise: Exercise, count: Int)
    case hold(exercise: Exercise, seconds: Int)

    public var exercise: Exercise {
        switch self {
        case .reps(let exercise, _): return exercise
        case .hold(let exercise, _): return exercise
        }
    }

    public var isHold: Bool {
        if case .hold = self { return true }
        return false
    }

    public var displayString: String {
        switch self {
        case .reps(let exercise, let count):
            return "\(exercise.displayName) · \(count) reps"
        case .hold(let exercise, let seconds):
            let mins = seconds / 60
            let secs = seconds % 60
            let secsStr = secs < 10 ? "0\(secs)" : "\(secs)"
            let timeStr = mins > 0 ? "\(mins):\(secsStr)" : "\(secs)s"
            return "\(exercise.displayName) · Hold for \(timeStr)"
        }
    }
}
