package com.flip54.core

import org.junit.Assert.*
import org.junit.Test

class PrescriptionFunctionTest {

    private val allEquipmentConfigs = listOf(
        Equipment.fullKit,
        Equipment.barOnly,
        Equipment.weightsOnly,
        Equipment.bodyWeightOnly
    )

    // ── Joker ────────────────────────────────────────────────────────────────

    @Test fun `joker beginner = 20 jumping jacks`() {
        val p = prescription(Card.Joker(JokerVariant.RED), Equipment.bodyWeightOnly, Difficulty.BEGINNER)
        assertEquals(Prescription.Reps(Exercise.JUMPING_JACKS, 20), p)
    }

    @Test fun `joker standard = 40 jumping jacks`() {
        val p = prescription(Card.Joker(JokerVariant.BLACK), Equipment.bodyWeightOnly, Difficulty.STANDARD)
        assertEquals(Prescription.Reps(Exercise.JUMPING_JACKS, 40), p)
    }

    @Test fun `joker advanced = 80 jumping jacks`() {
        val p = prescription(Card.Joker(JokerVariant.RED), Equipment.fullKit, Difficulty.ADVANCED)
        assertEquals(Prescription.Reps(Exercise.JUMPING_JACKS, 80), p)
    }

    // ── Ace hold seconds ─────────────────────────────────────────────────────

    @Test fun `ace seconds per difficulty`() {
        assertEquals(30,  roundToFive(60 * 0.5))
        assertEquals(60,  roundToFive(60 * 1.0))
        assertEquals(120, roundToFive(60 * 2.0))
    }

    @Test fun `ace hearts = wall sit for all configs`() {
        for (eq in allEquipmentConfigs) {
            for (diff in Difficulty.entries) {
                val p = prescription(Card.Standard(Suit.HEARTS, Rank.ACE), eq, diff)
                val expectedSecs = roundToFive(60 * diff.multiplier)
                assertEquals(Prescription.Hold(Exercise.WALL_SIT, expectedSecs), p)
            }
        }
    }

    @Test fun `ace spades with bar = dead hang`() {
        for (eq in listOf(Equipment.fullKit, Equipment.barOnly)) {
            for (diff in Difficulty.entries) {
                val p = prescription(Card.Standard(Suit.SPADES, Rank.ACE), eq, diff)
                val expectedSecs = roundToFive(60 * diff.multiplier)
                assertEquals(Prescription.Hold(Exercise.DEAD_HANG, expectedSecs), p)
            }
        }
    }

    @Test fun `ace spades without bar = push-up hold`() {
        for (eq in listOf(Equipment.bodyWeightOnly, Equipment.weightsOnly)) {
            for (diff in Difficulty.entries) {
                val p = prescription(Card.Standard(Suit.SPADES, Rank.ACE), eq, diff)
                val expectedSecs = roundToFive(60 * diff.multiplier)
                assertEquals(Prescription.Hold(Exercise.PUSH_UP_HOLD, expectedSecs), p)
            }
        }
    }

    @Test fun `ace clubs = plank`() {
        for (eq in allEquipmentConfigs) {
            for (diff in Difficulty.entries) {
                val p = prescription(Card.Standard(Suit.CLUBS, Rank.ACE), eq, diff)
                val expectedSecs = roundToFive(60 * diff.multiplier)
                assertEquals(Prescription.Hold(Exercise.PLANK, expectedSecs), p)
            }
        }
    }

    @Test fun `ace diamonds = hollow body hold`() {
        for (eq in allEquipmentConfigs) {
            for (diff in Difficulty.entries) {
                val p = prescription(Card.Standard(Suit.DIAMONDS, Rank.ACE), eq, diff)
                val expectedSecs = roundToFive(60 * diff.multiplier)
                assertEquals(Prescription.Hold(Exercise.HOLLOW_BODY_HOLD, expectedSecs), p)
            }
        }
    }

    // ── Movement pools ───────────────────────────────────────────────────────

    @Test fun `hearts bodyweight pool contains squat family`() {
        val pool = movementPool(Suit.HEARTS, Equipment.bodyWeightOnly)
        assertTrue(pool.contains(Exercise.BODYWEIGHT_SQUAT))
        assertTrue(pool.contains(Exercise.LUNGE))
        assertFalse(pool.contains(Exercise.GOBLET_SQUAT))
    }

    @Test fun `hearts with weights adds goblet squat`() {
        val pool = movementPool(Suit.HEARTS, Equipment.weightsOnly)
        assertTrue(pool.contains(Exercise.GOBLET_SQUAT))
        assertTrue(pool.contains(Exercise.BODYWEIGHT_SQUAT))
    }

    @Test fun `spades bodyweight pool = push-up and hindu push-up only`() {
        val pool = movementPool(Suit.SPADES, Equipment.bodyWeightOnly)
        assertEquals(listOf(Exercise.PUSH_UP, Exercise.HINDU_PUSH_UP), pool)
    }

    @Test fun `spades with bar adds pull-ups`() {
        val pool = movementPool(Suit.SPADES, Equipment.barOnly)
        assertTrue(pool.contains(Exercise.PULL_UP))
        assertTrue(pool.contains(Exercise.PUSH_UP))
    }

    @Test fun `spades with weights adds curl press triceps`() {
        val pool = movementPool(Suit.SPADES, Equipment.weightsOnly)
        assertTrue(pool.contains(Exercise.BICEP_CURL))
        assertTrue(pool.contains(Exercise.SHOULDER_PRESS))
        assertTrue(pool.contains(Exercise.TRICEP_EXTENSION))
    }

    @Test fun `clubs pool bodyweight + weights adds thruster`() {
        val bw = movementPool(Suit.CLUBS, Equipment.bodyWeightOnly)
        assertTrue(bw.contains(Exercise.BURPEE))
        assertFalse(bw.contains(Exercise.THRUSTER))
        val weighted = movementPool(Suit.CLUBS, Equipment.weightsOnly)
        assertTrue(weighted.contains(Exercise.THRUSTER))
    }

    @Test fun `diamonds pool bodyweight + weights adds weighted sit-up`() {
        val bw = movementPool(Suit.DIAMONDS, Equipment.bodyWeightOnly)
        assertEquals(listOf(Exercise.SIT_UP, Exercise.RUSSIAN_TWIST), bw)
        val weighted = movementPool(Suit.DIAMONDS, Equipment.weightsOnly)
        assertTrue(weighted.contains(Exercise.WEIGHTED_SIT_UP))
    }

    // ── Rep counts ───────────────────────────────────────────────────────────

    @Test fun `number card reps = pip times difficulty`() {
        val p = prescription(Card.Standard(Suit.HEARTS, Rank.FIVE), Equipment.bodyWeightOnly, Difficulty.STANDARD)
        assertTrue(p is Prescription.Reps)
        assertEquals(5, (p as Prescription.Reps).count)
    }

    @Test fun `face cards = 10 reps times difficulty`() {
        for (rank in listOf(Rank.JACK, Rank.QUEEN, Rank.KING)) {
            val beg = prescription(Card.Standard(Suit.HEARTS, rank), Equipment.bodyWeightOnly, Difficulty.BEGINNER)
            assertEquals(5, (beg as Prescription.Reps).count)

            val std = prescription(Card.Standard(Suit.HEARTS, rank), Equipment.bodyWeightOnly, Difficulty.STANDARD)
            assertEquals(10, (std as Prescription.Reps).count)

            val adv = prescription(Card.Standard(Suit.HEARTS, rank), Equipment.bodyWeightOnly, Difficulty.ADVANCED)
            assertEquals(20, (adv as Prescription.Reps).count)
        }
    }

    // ── Determinism ──────────────────────────────────────────────────────────

    @Test fun `pool selection is deterministic per suit rank equipment`() {
        val card = Card.Standard(Suit.SPADES, Rank.SEVEN)
        val p1 = prescription(card, Equipment.fullKit, Difficulty.STANDARD)
        val p2 = prescription(card, Equipment.fullKit, Difficulty.STANDARD)
        assertEquals(p1, p2)
    }

    @Test fun `different ranks in same suit yield different exercises`() {
        val exercises = listOf(Rank.TWO, Rank.THREE, Rank.FOUR, Rank.FIVE, Rank.SIX).map { rank ->
            val p = prescription(Card.Standard(Suit.SPADES, rank), Equipment.fullKit, Difficulty.STANDARD)
            (p as Prescription.Reps).exercise
        }.toSet()
        assertTrue("Expected variety across ranks", exercises.size >= 2)
    }

    // ── Full matrix coverage ─────────────────────────────────────────────────

    @Test fun `full matrix number and face cards = 576 cases`() {
        val numberAndFaceRanks = Rank.entries.filter { it != Rank.ACE }
        var caseCount = 0
        for (suit in Suit.entries) {
            for (rank in numberAndFaceRanks) {
                for (eq in allEquipmentConfigs) {
                    for (diff in Difficulty.entries) {
                        val p = prescription(Card.Standard(suit, rank), eq, diff)
                        assertTrue("Expected reps for $suit $rank", p is Prescription.Reps)
                        assertTrue("Zero reps for $suit $rank", (p as Prescription.Reps).count > 0)
                        caseCount++
                    }
                }
            }
        }
        assertEquals(576, caseCount)
    }

    @Test fun `ace matrix = 48 hold prescriptions`() {
        var caseCount = 0
        for (suit in Suit.entries) {
            for (eq in allEquipmentConfigs) {
                for (diff in Difficulty.entries) {
                    val p = prescription(Card.Standard(suit, Rank.ACE), eq, diff)
                    assertTrue("Expected hold for ace $suit", p is Prescription.Hold)
                    assertTrue((p as Prescription.Hold).seconds > 0)
                    caseCount++
                }
            }
        }
        assertEquals(48, caseCount)
    }
}
