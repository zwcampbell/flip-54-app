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

    // ── Ace holds ──────────────────────────────────────────────────────────

    @Test("Aces · hold seconds per difficulty")
    func aceHoldSeconds() {
        // Beginner: roundToFive(60 * 0.75) = roundToFive(45) = 45
        #expect(roundToFive(60 * 0.75) == 45)
        // Standard: roundToFive(60 * 1.0) = 60
        #expect(roundToFive(60 * 1.0) == 60)
        // Advanced: roundToFive(60 * 1.25) = roundToFive(75) = 75
        #expect(roundToFive(60 * 1.25) == 75)
    }

    @Test("Ace Hearts → push-up hold (all equipment, all difficulties)")
    func aceHearts() {
        for (eq, _) in allEquipmentConfigs {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .hearts, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .pushUpHold, seconds: expectedSecs))
            }
        }
    }

    @Test("Ace Spades with bar → dead hang")
    func aceSpadeWithBar() {
        for diff in Difficulty.allCases {
            let p = prescription(for: .standard(suit: .spades, rank: .ace), equipment: .fullKit, difficulty: diff)
            let expectedSecs = roundToFive(60 * diff.multiplier)
            #expect(p == .hold(exercise: .deadHang, seconds: expectedSecs))
        }
        for diff in Difficulty.allCases {
            let p = prescription(for: .standard(suit: .spades, rank: .ace), equipment: .barOnly, difficulty: diff)
            let expectedSecs = roundToFive(60 * diff.multiplier)
            #expect(p == .hold(exercise: .deadHang, seconds: expectedSecs))
        }
    }

    @Test("Ace Spades without bar → hollow body hold")
    func aceSpadesNoBar() {
        for diff in Difficulty.allCases {
            let p = prescription(for: .standard(suit: .spades, rank: .ace), equipment: .bodyWeightOnly, difficulty: diff)
            let expectedSecs = roundToFive(60 * diff.multiplier)
            #expect(p == .hold(exercise: .hollowBodyHold, seconds: expectedSecs))
        }
        for diff in Difficulty.allCases {
            let p = prescription(for: .standard(suit: .spades, rank: .ace), equipment: .weightsOnly, difficulty: diff)
            let expectedSecs = roundToFive(60 * diff.multiplier)
            #expect(p == .hold(exercise: .hollowBodyHold, seconds: expectedSecs))
        }
    }

    @Test("Ace Clubs → wall sit (all equipment)")
    func aceClubs() {
        for (eq, _) in allEquipmentConfigs {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .clubs, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .wallSit, seconds: expectedSecs))
            }
        }
    }

    @Test("Ace Diamonds → plank (all equipment)")
    func aceDiamonds() {
        for (eq, _) in allEquipmentConfigs {
            for diff in Difficulty.allCases {
                let p = prescription(for: .standard(suit: .diamonds, rank: .ace), equipment: eq, difficulty: diff)
                let expectedSecs = roundToFive(60 * diff.multiplier)
                #expect(p == .hold(exercise: .plank, seconds: expectedSecs))
            }
        }
    }

    // ── Face cards (flat 10) ───────────────────────────────────────────────

    @Test("Face cards: beginner → 8 reps (ceil(10 * 0.75))")
    func faceCardBeginner() {
        for rank in [Rank.jack, .queen, .king] {
            let p = prescription(for: .standard(suit: .hearts, rank: rank), equipment: .bodyWeightOnly, difficulty: .beginner)
            #expect(p == .reps(exercise: .pushUp, count: 8))
        }
    }

    @Test("Face cards: standard → 10 reps")
    func faceCardStandard() {
        for rank in [Rank.jack, .queen, .king] {
            let p = prescription(for: .standard(suit: .hearts, rank: rank), equipment: .bodyWeightOnly, difficulty: .standard)
            #expect(p == .reps(exercise: .pushUp, count: 10))
        }
    }

    @Test("Face cards: advanced → 13 reps (ceil(10 * 1.25))")
    func faceCardAdvanced() {
        for rank in [Rank.jack, .queen, .king] {
            let p = prescription(for: .standard(suit: .hearts, rank: rank), equipment: .bodyWeightOnly, difficulty: .advanced)
            #expect(p == .reps(exercise: .pushUp, count: 13))
        }
    }

    // ── Suit mappings ──────────────────────────────────────────────────────

    @Test("Hearts → push-up regardless of equipment")
    func heartsExercise() {
        for (eq, _) in allEquipmentConfigs {
            let p = prescription(for: .standard(suit: .hearts, rank: .seven), equipment: eq, difficulty: .standard)
            #expect(p == .reps(exercise: .pushUp, count: 7))
        }
    }

    @Test("Spades with bar → pull-up")
    func spadesWithBar() {
        for eq in [Equipment.fullKit, .barOnly] {
            let p = prescription(for: .standard(suit: .spades, rank: .seven), equipment: eq, difficulty: .standard)
            #expect(p == .reps(exercise: .pullUp, count: 7))
        }
    }

    @Test("Spades without bar → Hindu push-up")
    func spadesNoBar() {
        for eq in [Equipment.bodyWeightOnly, .weightsOnly] {
            let p = prescription(for: .standard(suit: .spades, rank: .seven), equipment: eq, difficulty: .standard)
            #expect(p == .reps(exercise: .hinduPushUp, count: 7))
        }
    }

    @Test("Clubs with weights → goblet squat, pip×1")
    func clubsWithWeights() {
        for eq in [Equipment.fullKit, .weightsOnly] {
            let p = prescription(for: .standard(suit: .clubs, rank: .seven), equipment: eq, difficulty: .standard)
            #expect(p == .reps(exercise: .gobletSquat, count: 7))
        }
    }

    @Test("Clubs without weights → body-weight squat, pip×2")
    func clubsNoWeights() {
        for eq in [Equipment.bodyWeightOnly, .barOnly] {
            let p = prescription(for: .standard(suit: .clubs, rank: .seven), equipment: eq, difficulty: .standard)
            #expect(p == .reps(exercise: .bodyweightSquat, count: 14))
        }
    }

    @Test("Diamonds → sit-up regardless of equipment")
    func diamondsExercise() {
        for (eq, _) in allEquipmentConfigs {
            let p = prescription(for: .standard(suit: .diamonds, rank: .seven), equipment: eq, difficulty: .standard)
            #expect(p == .reps(exercise: .sitUp, count: 7))
        }
    }

    // ── Documented example from spec ───────────────────────────────────────

    @Test("Spec example: Club 7, body-weight, beginner → 11 squats")
    func specExample() {
        // ceil(7 × 2 × 0.75) = ceil(10.5) = 11
        let p = prescription(for: .standard(suit: .clubs, rank: .seven), equipment: .bodyWeightOnly, difficulty: .beginner)
        #expect(p == .reps(exercise: .bodyweightSquat, count: 11))
    }

    @Test("Beginner 7 Hearts → 6 push-ups (ceil(7 * 0.75))")
    func beginnerSevenHearts() {
        let p = prescription(for: .standard(suit: .hearts, rank: .seven), equipment: .bodyWeightOnly, difficulty: .beginner)
        #expect(p == .reps(exercise: .pushUp, count: 6))
    }

    @Test("Advanced 7 Hearts → 9 push-ups (ceil(7 * 1.25))")
    func advancedSevenHearts() {
        let p = prescription(for: .standard(suit: .hearts, rank: .seven), equipment: .bodyWeightOnly, difficulty: .advanced)
        #expect(p == .reps(exercise: .pushUp, count: 9))
    }

    // ── Full 648-case matrix ───────────────────────────────────────────────

    @Test("Full matrix: all number+face cards × 4 equipment × 3 difficulty")
    func fullMatrix() {
        let numberAndFaceRanks = Rank.allCases.filter { $0 != .ace }
        var caseCount = 0

        for suit in Suit.allCases {
            for rank in numberAndFaceRanks {
                for (eq, eqName) in allEquipmentConfigs {
                    for diff in Difficulty.allCases {
                        let card = Card.standard(suit: suit, rank: rank)
                        let p = prescription(for: card, equipment: eq, difficulty: diff)
                        // All should be reps prescriptions for non-ace cards
                        if case .reps(_, let count) = p {
                            #expect(count > 0, "Zero reps for \(suit) \(rank) \(eqName) \(diff)")
                        } else {
                            Issue.record("Expected reps prescription for \(suit) \(rank) \(eqName) \(diff), got hold")
                        }
                        caseCount += 1
                    }
                }
            }
        }
        // 4 suits × 12 non-ace ranks × 4 equipment × 3 difficulty = 576
        // Plus 4 suits × 1 ace × 4 equipment × 3 difficulty = 48
        // Plus 2 joker variants × 4 equipment × 3 difficulty = 24
        // number+face only here: 4 × 12 × 4 × 3 = 576
        #expect(caseCount == 576)
    }

    @Test("Full matrix: all aces × 4 equipment × 3 difficulty = 48 holds")
    func aceMatrix() {
        var caseCount = 0
        for suit in Suit.allCases {
            for (eq, _) in allEquipmentConfigs {
                for diff in Difficulty.allCases {
                    let p = prescription(for: .standard(suit: suit, rank: .ace), equipment: eq, difficulty: diff)
                    if case .hold(_, let secs) = p {
                        #expect(secs > 0)
                    } else {
                        Issue.record("Expected hold prescription for ace")
                    }
                    caseCount += 1
                }
            }
        }
        #expect(caseCount == 48)
    }
}
