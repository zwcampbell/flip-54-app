import Foundation
import Flip54Core

/// Words shown on both the iPhone and the watch. Both apps read them from
/// here so the two say the same thing in the same way. Casing is applied
/// where they're shown, the same way on both.
public enum Copy {

    // MARK: Difficulty

    /// "×2.0"
    public static func multiplier(_ difficulty: Difficulty) -> String {
        String(format: "×%.1f", difficulty.multiplier)
    }

    /// "×0.5 reps — great for starting out"
    public static func description(_ difficulty: Difficulty) -> String {
        let m = multiplier(difficulty)
        switch difficulty {
        case .beginner:  return "\(m) reps — great for starting out"
        case .standard:  return "\(m) reps — the full deck challenge"
        case .advanced:  return "\(m) reps — for seasoned athletes"
        }
    }

    /// "ADVANCED + HALF DECK", as on the Workout tab.
    public static func difficultySummary(_ difficulty: Difficulty, halfDeck: Bool) -> String {
        "\(difficulty.displayName.uppercased()) + \(deckSizeName(halfDeck: halfDeck).uppercased())"
    }

    // MARK: Deck size

    public static func deckSizeName(halfDeck: Bool) -> String { halfDeck ? "Half Deck" : "Full Deck" }

    public static let fullDeckDetail = "54 cards · every card + 2 jokers"
    public static let halfDeckDetail = "27 cards · A/K/Q/J/10/9 every suit + two 8s + 1 joker"

    // MARK: Equipment

    public static let weights = "Weights"
    public static let weightsDetail = "Adds curls, goblet squats, thrusters, and more"
    public static let pullUpBar = "Pull-up Bar"
    public static let pullUpBarDetail = "Adds pull-ups to upper body workouts and dead-hang holds"
    public static let bodyweightOnly = "Body-weight only? No problem — we've got you."

    /// "Weights + Pull-up Bar", or "Bodyweight" with neither.
    public static func equipmentSummary(hasWeights: Bool, hasPullUpBar: Bool) -> String {
        var parts: [String] = []
        if hasWeights   { parts.append(weights) }
        if hasPullUpBar { parts.append(pullUpBar) }
        return parts.isEmpty ? "Bodyweight" : parts.joined(separator: " + ")
    }

    // MARK: Card style

    public static let equipped = "Equipped"

    /// Why a deck isn't available yet: "1 more workout", "3 more workouts",
    /// or "Coming soon" for a deck with no way to unlock it yet.
    public static func unlockHint(workoutsLeft: Int?) -> String {
        guard let left = workoutsLeft else { return "Coming soon" }
        return left == 1 ? "1 more workout" : "\(left) more workouts"
    }

    // MARK: Ending early

    public static let endEarly = "End Early"
    public static let endEarlyQuestion = "End workout early?"
    public static let endWorkout = "End Workout"
    public static let keepGoing = "Keep Going"

    public static func endEarlyMessage(cardsCompleted: Int) -> String {
        cardsCompleted > 0
            ? "Your \(cardsCompleted) completed \(cardsCompleted == 1 ? "card" : "cards") will be saved to History."
            : "Nothing has been completed yet, so this workout won't be saved to History."
    }

    // MARK: Summary

    public static let totalReps = "Total Reps"

    /// "54 cards. Every single one."
    public static func deckCleared(cards: Int) -> String { "\(cards) cards. Every single one." }
}
