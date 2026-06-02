package com.flip54.core

/**
 * Returns the exercise prescription for a given card, equipment, and difficulty.
 *
 * Suit → body region:
 *   HEARTS   → lower body
 *   SPADES   → upper body
 *   CLUBS    → total body
 *   DIAMONDS → core
 *   Joker    → conditioning (jumping jacks)
 */
fun prescription(card: Card, equipment: Equipment, difficulty: Difficulty): Prescription {
    val multiplier = difficulty.multiplier
    return when (card) {
        is Card.Joker -> Prescription.Reps(Exercise.JUMPING_JACKS, roundUp(40 * multiplier))

        is Card.Standard -> when (card.rank) {
            Rank.ACE -> {
                val seconds = roundToFive(60 * multiplier)
                Prescription.Hold(aceExercise(card.suit, equipment), seconds)
            }
            else -> {
                val exercise = movementExercise(card.suit, card.rank, equipment)
                val basePip = card.rank.pipValue ?: 10
                val count = roundUp(basePip * multiplier)
                Prescription.Reps(exercise, count)
            }
        }
    }
}

internal fun aceExercise(suit: Suit, equipment: Equipment): Exercise = when (suit) {
    Suit.HEARTS   -> Exercise.WALL_SIT
    Suit.SPADES   -> if (equipment.hasPullUpBar) Exercise.DEAD_HANG else Exercise.PUSH_UP_HOLD
    Suit.CLUBS    -> Exercise.PLANK
    Suit.DIAMONDS -> Exercise.HOLLOW_BODY_HOLD
}

internal fun movementExercise(suit: Suit, rank: Rank, equipment: Equipment): Exercise {
    val pool = movementPool(suit, equipment)
    val idx = rankIndex(rank) % pool.size
    return pool[idx]
}

internal fun movementPool(suit: Suit, equipment: Equipment): List<Exercise> = when (suit) {
    Suit.HEARTS -> buildList {
        add(Exercise.BODYWEIGHT_SQUAT)
        add(Exercise.LUNGE)
        add(Exercise.JUMPING_SQUAT)
        if (equipment.hasWeights) add(Exercise.GOBLET_SQUAT)
    }
    Suit.SPADES -> buildList {
        add(Exercise.PUSH_UP)
        add(Exercise.HINDU_PUSH_UP)
        if (equipment.hasWeights) {
            add(Exercise.BICEP_CURL)
            add(Exercise.SHOULDER_PRESS)
            add(Exercise.TRICEP_EXTENSION)
        }
        if (equipment.hasPullUpBar) add(Exercise.PULL_UP)
    }
    Suit.CLUBS -> buildList {
        add(Exercise.BURPEE)
        add(Exercise.MOUNTAIN_CLIMBER)
        add(Exercise.JUMPING_SQUAT)
        if (equipment.hasWeights) add(Exercise.THRUSTER)
    }
    Suit.DIAMONDS -> buildList {
        add(Exercise.SIT_UP)
        add(Exercise.RUSSIAN_TWIST)
        if (equipment.hasWeights) add(Exercise.WEIGHTED_SIT_UP)
    }
}

internal fun rankIndex(rank: Rank): Int = when (rank) {
    Rank.TWO   -> 0
    Rank.THREE -> 1
    Rank.FOUR  -> 2
    Rank.FIVE  -> 3
    Rank.SIX   -> 4
    Rank.SEVEN -> 5
    Rank.EIGHT -> 6
    Rank.NINE  -> 7
    Rank.TEN   -> 8
    Rank.JACK  -> 9
    Rank.QUEEN -> 10
    Rank.KING  -> 11
    Rank.ACE   -> 12
}

internal fun roundUp(value: Double): Int = kotlin.math.ceil(value).toInt()

internal fun roundToFive(value: Double): Int = (kotlin.math.round(value / 5) * 5).toInt()
