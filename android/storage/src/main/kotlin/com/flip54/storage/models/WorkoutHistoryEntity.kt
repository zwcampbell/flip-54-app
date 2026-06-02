package com.flip54.storage.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.flip54.core.Difficulty
import com.flip54.core.Suit
import java.util.UUID

@Entity(tableName = "workout_history")
data class WorkoutHistoryEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val completedAt: Long,
    val durationMs: Long,
    val deckId: String,
    val difficultyRaw: String,
    val totalReps: Int,
    val holdSecondsCompleted: Int,
    val cardCount: Int,
    val skipCount: Int,
    val heartsReps: Int = 0,
    val spadesReps: Int = 0,
    val clubsReps: Int = 0,
    val diamondsReps: Int = 0,
    val jumpingJacks: Int = 0
) {
    val difficulty: Difficulty
        get() = Difficulty.entries.firstOrNull { it.name == difficultyRaw } ?: Difficulty.STANDARD

    val repsBySuit: Map<Suit, Int>
        get() = mapOf(
            Suit.HEARTS   to heartsReps,
            Suit.SPADES   to spadesReps,
            Suit.CLUBS    to clubsReps,
            Suit.DIAMONDS to diamondsReps
        )
}
