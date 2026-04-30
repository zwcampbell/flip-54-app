/// Returns the exercise prescription for a given card, equipment, and difficulty.
/// This is the single source of truth for all exercise/rep/hold calculations.
public func prescription(
    for card: Card,
    equipment: Equipment,
    difficulty: Difficulty
) -> Prescription {
    let multiplier = difficulty.multiplier

    switch card {
    case .joker:
        return .reps(exercise: .jumpingJacks, count: roundUp(40 * multiplier))

    case .standard(let suit, .ace):
        let seconds = roundToFive(60 * multiplier)
        return .hold(exercise: aceExercise(for: suit, equipment: equipment), seconds: seconds)

    case .standard(let suit, let rank):
        let exercise = movementExercise(for: suit, equipment: equipment)
        let basePip = rank.pipValue ?? 10  // face cards = 10
        let eqMult = equipmentRepMultiplier(suit: suit, equipment: equipment)
        let count = roundUp(Double(basePip) * eqMult * multiplier)
        return .reps(exercise: exercise, count: count)
    }
}

// MARK: - Private helpers

func aceExercise(for suit: Suit, equipment: Equipment) -> Exercise {
    switch suit {
    case .hearts:   return .pushUpHold
    case .spades:   return equipment.hasPullUpBar ? .deadHang : .hollowBodyHold
    case .clubs:    return .wallSit
    case .diamonds: return .plank
    }
}

func movementExercise(for suit: Suit, equipment: Equipment) -> Exercise {
    switch suit {
    case .hearts:   return .pushUp
    case .spades:   return equipment.hasPullUpBar ? .pullUp : .hinduPushUp
    case .clubs:    return equipment.hasWeights ? .gobletSquat : .bodyweightSquat
    case .diamonds: return .sitUp
    }
}

func equipmentRepMultiplier(suit: Suit, equipment: Equipment) -> Double {
    // Body-weight squats are 2× pip value when no weights available
    suit == .clubs && !equipment.hasWeights ? 2.0 : 1.0
}

func roundUp(_ value: Double) -> Int {
    Int(value.rounded(.up))
}

func roundToFive(_ value: Double) -> Int {
    Int((value / 5).rounded()) * 5
}
