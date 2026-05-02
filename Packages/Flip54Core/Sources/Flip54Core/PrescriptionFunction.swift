/// Returns the exercise prescription for a given card, equipment, and difficulty.
/// This is the single source of truth for all exercise/rep/hold calculations.
///
/// Suit → body region:
///   ♥ Hearts   → lower body
///   ♠ Spades   → upper body
///   ♣ Clubs    → total body
///   ♦ Diamonds → core
///   🃏 Joker   → conditioning (jumping jacks)
///
/// Within a suit, the specific exercise is picked from a pool that grows with
/// the user's available equipment, indexed deterministically by rank so a
/// workout features a varied mix while staying repeatable.
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
        let exercise = movementExercise(for: suit, rank: rank, equipment: equipment)
        let basePip = rank.pipValue ?? 10  // face cards = 10
        let count = roundUp(Double(basePip) * multiplier)
        return .reps(exercise: exercise, count: count)
    }
}

// MARK: - Suit → exercise

func aceExercise(for suit: Suit, equipment: Equipment) -> Exercise {
    switch suit {
    case .hearts:   return .wallSit          // lower body
    case .spades:   return equipment.hasPullUpBar ? .deadHang : .pushUpHold  // upper body
    case .clubs:    return .plank            // total body
    case .diamonds: return .hollowBodyHold   // core
    }
}

func movementExercise(for suit: Suit, rank: Rank, equipment: Equipment) -> Exercise {
    let pool = movementPool(for: suit, equipment: equipment)
    // Deterministic per-rank index so different cards in the same suit pick
    // different exercises from the pool.
    let idx = rankIndex(rank) % pool.count
    return pool[idx]
}

/// Body-weight is always present. Add weighted moves when the user has weights;
/// add pull-ups when the user has a pull-up bar (upper body only).
func movementPool(for suit: Suit, equipment: Equipment) -> [Exercise] {
    switch suit {
    case .hearts:  // lower body
        var pool: [Exercise] = [.bodyweightSquat, .lunge, .jumpingSquat]
        if equipment.hasWeights { pool.append(.gobletSquat) }
        return pool

    case .spades:  // upper body
        var pool: [Exercise] = [.pushUp, .hinduPushUp]
        if equipment.hasWeights {
            pool += [.bicepCurl, .shoulderPress, .tricepExtension]
        }
        if equipment.hasPullUpBar { pool.append(.pullUp) }
        return pool

    case .clubs:   // total body
        var pool: [Exercise] = [.burpee, .mountainClimber, .jumpingSquat]
        if equipment.hasWeights { pool.append(.thruster) }
        return pool

    case .diamonds:  // core
        var pool: [Exercise] = [.sitUp, .russianTwist]
        if equipment.hasWeights { pool.append(.weightedSitUp) }
        return pool
    }
}

/// Ordinal of a rank in the standard 2..A sequence, used for pool indexing.
func rankIndex(_ rank: Rank) -> Int {
    switch rank {
    case .two: return 0
    case .three: return 1
    case .four: return 2
    case .five: return 3
    case .six: return 4
    case .seven: return 5
    case .eight: return 6
    case .nine: return 7
    case .ten: return 8
    case .jack: return 9
    case .queen: return 10
    case .king: return 11
    case .ace: return 12
    }
}

func roundUp(_ value: Double) -> Int {
    Int(value.rounded(.up))
}

func roundToFive(_ value: Double) -> Int {
    Int((value / 5).rounded()) * 5
}
