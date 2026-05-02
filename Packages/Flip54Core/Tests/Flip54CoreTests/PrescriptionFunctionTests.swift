import Testing
@testable import Flip54Core

// MARK: - Equipment configurations

private let allEquipmentConfigs: [(Equipment, String)] = [
    (.fullKit,        "fullKit"),
    (.barOnly,        "barOnly"),
    (.weightsOnly,    "weightsOnly"),
    (.bodyWeightOnly, "bodyWeightOnly"),
]

// MARK: - Exhaustive matrix

@Suite("PrescriptionFunction — exhaustive matrix")
struct PrescriptionFunctionTests {

    // ── Joker ──────────────────────────────────────────────────────────────

    @Test("Joker · beginner → 30 jumping jacks")
    func jokerBeginner() {
        let p = prescription(for: .joker(variant: .red), equipment: .bodyWeightOnly, difficulty: .beginner)
        #expect(p == .reps(exercise: .jumpingJacks, count: 30))
    }

    @Test("Joker · standard → 40 jumping jacks")
    func jokerStandard() {
        let p = prescription(for: .joker(variant: .black), equipment: .bodyWeightOnly, difficulty: .standard)
        #expect(p == .reps(exercise: .jumpingJacks, count: 40))
    }

    @Test("Joker · advanced → 50 jumping jacks")
    func jokerAdvanced() {
        let p = prescription(for: .joker(variant: .red), equipment: .fullKit, difficulty: .advanced)
        #expect(p == .reps(exercise: .jumpingJacks, count: 50))
    }

    // ── Ace holds (suit → body region) ─────────────────────────────────────

    @Test("Ace seconds per difficulty")
    func aceHoldSeconds() {
        #expect(roundToFive(60 * 0.75) == 45)
        #expect(roundToFive(60 * 1.0)  == 60)
        #expect(roundToFive(60 * 1.25) == 75)
    }

    @Test("Ace Hearts (lower body) → wall sit")
    func aceHearts() {
        for (eq, _) in allEquipmentConfigs {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .hearts, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .wallSit, seconds: expectedSecs))
            }
        }
    }

    @Test("Ace Spades (upper body) with bar → dead hang")
    func aceSpadeWithBar() {
        for eq in [Equipment.fullKit, .barOnly] {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .spades, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .deadHang, seconds: expectedSecs))
            }
        }
    }

    @Test("Ace Spades (upper body) without bar → push-up hold")
    func aceSpadesNoBar() {
        for eq in [Equipment.bodyWeightOnly, .weightsOnly] {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .spades, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .pushUpHold, seconds: expectedSecs))
            }
        }
    }

    @Test("Ace Clubs (total body) → plank")
    func aceClubs() {
        for (eq, _) in allEquipmentConfigs {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .clubs, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .plank, seconds: expectedSecs))
            }
        }
    }

    @Test("Ace Diamonds (core) → hollow body hold")
    func aceDiamonds() {
        for (eq, _) in allEquipmentConfigs {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .diamonds, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .hollowBodyHold, seconds: expectedSecs))
            }
        }
    }

    // ── Movement pools ─────────────────────────────────────────────────────

    @Test("Hearts (lower body) bodyweight pool always includes squat-family moves")
    func heartsBodyweightPool() {
        let pool = movementPool(for: .hearts, equipment: .bodyWeightOnly)
        #expect(pool.contains(.bodyweightSquat))
        #expect(pool.contains(.lunge))
        #expect(!pool.contains(.gobletSquat))
    }

    @Test("Hearts (lower body) with weights adds goblet squats")
    func heartsWithWeights() {
        let pool = movementPool(for: .hearts, equipment: .weightsOnly)
        #expect(pool.contains(.gobletSquat))
        #expect(pool.contains(.bodyweightSquat))
    }

    @Test("Spades (upper body) bodyweight pool: push-up + Hindu push-up only")
    func spadesBodyweightPool() {
        let pool = movementPool(for: .spades, equipment: .bodyWeightOnly)
        #expect(pool == [.pushUp, .hinduPushUp])
    }

    @Test("Spades (upper body) with bar adds pull-ups")
    func spadesWithBar() {
        let pool = movementPool(for: .spades, equipment: .barOnly)
        #expect(pool.contains(.pullUp))
        #expect(pool.contains(.pushUp))
    }

    @Test("Spades (upper body) with weights adds curl/press/triceps")
    func spadesWithWeights() {
        let pool = movementPool(for: .spades, equipment: .weightsOnly)
        #expect(pool.contains(.bicepCurl))
        #expect(pool.contains(.shoulderPress))
        #expect(pool.contains(.tricepExtension))
        #expect(pool.contains(.pushUp))
    }

    @Test("Clubs (total body) pool: bodyweight always; weights adds thruster")
    func clubsPool() {
        let bw = movementPool(for: .clubs, equipment: .bodyWeightOnly)
        #expect(bw.contains(.burpee))
        #expect(bw.contains(.mountainClimber))
        #expect(!bw.contains(.thruster))

        let weighted = movementPool(for: .clubs, equipment: .weightsOnly)
        #expect(weighted.contains(.thruster))
    }

    @Test("Diamonds (core) pool: bodyweight always; weights adds weighted sit-ups")
    func diamondsPool() {
        let bw = movementPool(for: .diamonds, equipment: .bodyWeightOnly)
        #expect(bw == [.sitUp, .russianTwist])
        let weighted = movementPool(for: .diamonds, equipment: .weightsOnly)
        #expect(weighted.contains(.weightedSitUp))
    }

    // ── Rep counts ─────────────────────────────────────────────────────────

    @Test("Number-card reps = pip × difficulty (regardless of pool exercise)")
    func numberCardReps() {
        // 5♥ standard difficulty = 5 reps of whatever lower-body move maps.
        let p = prescription(for: .standard(suit: .hearts, rank: .five), equipment: .bodyWeightOnly, difficulty: .standard)
        if case .reps(_, let count) = p { #expect(count == 5) } else { Issue.record("expected reps") }
    }

    @Test("Face cards = 10 reps × difficulty")
    func faceCardReps() {
        for rank in [Rank.jack, .queen, .king] {
            let beg = prescription(for: .standard(suit: .hearts, rank: rank), equipment: .bodyWeightOnly, difficulty: .beginner)
            if case .reps(_, let c) = beg { #expect(c == 8) } else { Issue.record("expected reps") }

            let std = prescription(for: .standard(suit: .hearts, rank: rank), equipment: .bodyWeightOnly, difficulty: .standard)
            if case .reps(_, let c) = std { #expect(c == 10) } else { Issue.record("expected reps") }

            let adv = prescription(for: .standard(suit: .hearts, rank: rank), equipment: .bodyWeightOnly, difficulty: .advanced)
            if case .reps(_, let c) = adv { #expect(c == 13) } else { Issue.record("expected reps") }
        }
    }

    // ── Determinism: same card always picks same exercise ──────────────────

    @Test("Pool selection is deterministic per (suit, rank, equipment)")
    func deterministicSelection() {
        let card = Card.standard(suit: .spades, rank: .seven)
        let p1 = prescription(for: card, equipment: .fullKit, difficulty: .standard)
        let p2 = prescription(for: card, equipment: .fullKit, difficulty: .standard)
        #expect(p1 == p2)
    }

    @Test("Different ranks within a suit can yield different exercises")
    func variedExercisesPerSuit() {
        // With weights+bar (largest spades pool), different ranks should hit
        // different pool slots.
        let exs: Set<Exercise> = Set(
            [Rank.two, .three, .four, .five, .six].map { rank in
                let p = prescription(for: .standard(suit: .spades, rank: rank), equipment: .fullKit, difficulty: .standard)
                if case .reps(let ex, _) = p { return ex }
                return .pushUp
            }
        )
        #expect(exs.count >= 2, "Expected variety across ranks; got \(exs)")
    }

    // ── Full matrix coverage ───────────────────────────────────────────────

    @Test("Full matrix: number+face cards × 4 equipment × 3 difficulty = 576")
    func fullMatrix() {
        let numberAndFaceRanks = Rank.allCases.filter { $0 != .ace }
        var caseCount = 0
        for suit in Suit.allCases {
            for rank in numberAndFaceRanks {
                for (eq, eqName) in allEquipmentConfigs {
                    for diff in Difficulty.allCases {
                        let card = Card.standard(suit: suit, rank: rank)
                        let p = prescription(for: card, equipment: eq, difficulty: diff)
                        if case .reps(_, let count) = p {
                            #expect(count > 0, "Zero reps for \(suit) \(rank) \(eqName) \(diff)")
                        } else {
                            Issue.record("Expected reps prescription for \(suit) \(rank) \(eqName) \(diff)")
                        }
                        caseCount += 1
                    }
                }
            }
        }
        #expect(caseCount == 576)
    }

    @Test("Full matrix: aces × 4 equipment × 3 difficulty = 48 holds")
    func aceMatrix() {
        var caseCount = 0
        for suit in Suit.allCases {
            for (eq, _) in allEquipmentConfigs {
                for diff in Difficulty.allCases {
                    let p = prescription(for: .standard(suit: suit, rank: .ace), equipment: eq, difficulty: diff)
                    if case .hold(_, let secs) = p { #expect(secs > 0) }
                    else { Issue.record("Expected hold prescription for ace") }
                    caseCount += 1
                }
            }
        }
        #expect(caseCount == 48)
    }
}
