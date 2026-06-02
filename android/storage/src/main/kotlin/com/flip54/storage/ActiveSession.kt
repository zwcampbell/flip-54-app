package com.flip54.storage

import com.flip54.core.*
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class ActiveSession(
    val id: String = UUID.randomUUID().toString(),
    val deckId: String,
    val startedAtMs: Long,
    val equipment: Equipment,
    val difficulty: Difficulty,
    var drawPile: List<Card>,
    var discardPile: List<Card> = emptyList(),
    var currentCard: Card? = null,
    var totalRepsCompleted: Int = 0,
    var holdSecondsCompleted: Int = 0,
    var skipCount: Int = 0,
    var cardsCompleted: Int = 0,
    var heartsReps: Int = 0,
    var spadesReps: Int = 0,
    var clubsReps: Int = 0,
    var diamondsReps: Int = 0,
    var holdStartedAtMs: Long? = null,
    var holdElapsedMs: Long = 0,
    var pauseStartedAtMs: Long? = null,
    var totalPausedDurationMs: Long = 0
) {
    val cardsRemaining: Int get() = drawPile.size + (if (currentCard != null) 1 else 0)

    val deckSize: Int get() = drawPile.size + (if (currentCard != null) 1 else 0) + cardsCompleted

    val isComplete: Boolean get() = drawPile.isEmpty() && currentCard == null

    val repsBySuit: Map<Suit, Int> get() = mapOf(
        Suit.HEARTS   to heartsReps,
        Suit.SPADES   to spadesReps,
        Suit.CLUBS    to clubsReps,
        Suit.DIAMONDS to diamondsReps
    )

    fun flipNextCard(): ActiveSession {
        if (currentCard != null || drawPile.isEmpty()) return this
        val next = drawPile.last()
        return copy(
            drawPile = drawPile.dropLast(1),
            currentCard = next,
            holdElapsedMs = 0,
            holdStartedAtMs = null
        )
    }

    fun startHold(nowMs: Long): ActiveSession {
        val card = currentCard ?: return this
        if (!card.isAce) return this
        return copy(holdStartedAtMs = nowMs)
    }

    fun completeCurrentCard(reps: Int?, holdSeconds: Int?, nowMs: Long): ActiveSession {
        val card = currentCard ?: return this
        var s = this
        if (reps != null) {
            s = s.copy(totalRepsCompleted = s.totalRepsCompleted + reps)
            if (card is Card.Standard) {
                s = when (card.suit) {
                    Suit.HEARTS   -> s.copy(heartsReps = s.heartsReps + reps)
                    Suit.SPADES   -> s.copy(spadesReps = s.spadesReps + reps)
                    Suit.CLUBS    -> s.copy(clubsReps = s.clubsReps + reps)
                    Suit.DIAMONDS -> s.copy(diamondsReps = s.diamondsReps + reps)
                }
            }
        }
        if (holdSeconds != null) {
            s = s.copy(holdSecondsCompleted = s.holdSecondsCompleted + holdSeconds)
        }
        return s.copy(
            discardPile = s.discardPile + card,
            cardsCompleted = s.cardsCompleted + 1,
            currentCard = null,
            holdStartedAtMs = null,
            holdElapsedMs = 0
        )
    }

    fun skipCurrentCard(): ActiveSession {
        val card = currentCard ?: return this
        return copy(
            drawPile = listOf(card) + drawPile,
            skipCount = skipCount + 1,
            currentCard = null,
            holdStartedAtMs = null,
            holdElapsedMs = 0
        )
    }

    fun pause(nowMs: Long): ActiveSession {
        if (pauseStartedAtMs != null) return this
        val holdStart = holdStartedAtMs
        val extraElapsed = if (holdStart != null) nowMs - holdStart else 0L
        return copy(
            pauseStartedAtMs = nowMs,
            holdElapsedMs = holdElapsedMs + extraElapsed,
            holdStartedAtMs = null
        )
    }

    fun resume(nowMs: Long): ActiveSession {
        val pauseStart = pauseStartedAtMs ?: return this
        return copy(
            totalPausedDurationMs = totalPausedDurationMs + (nowMs - pauseStart),
            pauseStartedAtMs = null
        )
    }

    companion object {
        fun start(
            deck: List<Card>,
            deckId: String,
            equipment: Equipment,
            difficulty: Difficulty,
            nowMs: Long = System.currentTimeMillis()
        ): ActiveSession = ActiveSession(
            deckId = deckId,
            startedAtMs = nowMs,
            equipment = equipment,
            difficulty = difficulty,
            drawPile = deck.shuffled()
        )
    }
}
