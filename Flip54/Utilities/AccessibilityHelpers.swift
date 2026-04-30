import SwiftUI
import Flip54Core

// MARK: - Card accessibility label

extension Card {
    /// Human-readable VoiceOver label for a face-up card.
    var accessibilityLabel: String {
        switch self {
        case .joker(let variant):
            return "\(variant.rawValue.capitalized) Joker — Jumping Jacks"
        case .standard(let suit, let rank):
            return "\(rank.accessibilityName) of \(suit.accessibilityName)"
        }
    }

    /// Label when card is face-down.
    static let faceDownLabel = "Face-down card. Tap to flip."
}

extension Rank {
    var accessibilityName: String {
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
        case .jack:  return "Jack"
        case .queen: return "Queen"
        case .king:  return "King"
        case .ace:   return "Ace"
        }
    }
}

extension Suit {
    var accessibilityName: String {
        switch self {
        case .hearts:   return "Hearts"
        case .spades:   return "Spades"
        case .clubs:    return "Clubs"
        case .diamonds: return "Diamonds"
        }
    }
}

// MARK: - Prescription accessibility

extension Prescription {
    var accessibilityHint: String {
        switch self {
        case .reps(let exercise, let count):
            return "\(count) \(exercise.displayName)"
        case .hold(let exercise, let seconds):
            let m = seconds / 60
            let s = seconds % 60
            let timeStr = m > 0 ? "\(m) minute\(m > 1 ? "s" : "") \(s) seconds" : "\(s) seconds"
            return "\(exercise.displayName) — hold for \(timeStr)"
        }
    }
}

// MARK: - ReduceMotion environment helper

struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var reduceMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}

/// Inject system reduce-motion preference into the environment.
struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    func body(content: Content) -> some View {
        content.environment(\.reduceMotion, systemReduceMotion)
    }
}

extension View {
    func injectReduceMotion() -> some View {
        modifier(ReduceMotionModifier())
    }
}
