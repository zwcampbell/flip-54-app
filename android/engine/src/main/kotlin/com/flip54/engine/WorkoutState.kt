package com.flip54.engine

import com.flip54.core.Card
import com.flip54.core.Prescription

sealed class WorkoutState {
    data object Idle : WorkoutState()
    data object Shuffling : WorkoutState()
    data object CardFaceDown : WorkoutState()
    data class CardFaceUp(val card: Card, val prescription: Prescription) : WorkoutState()
    data class HoldStarting(val card: Card) : WorkoutState()
    data class Holding(val card: Card, val startTimeMs: Long, val durationSeconds: Int) : WorkoutState()
    data class HoldComplete(val card: Card, val secondsHeld: Int, val completedFully: Boolean) : WorkoutState()
    data class CardCompleting(val card: Card) : WorkoutState()
    data class CardSkipping(val card: Card) : WorkoutState()
    data class Paused(val previous: WorkoutState) : WorkoutState()
    data object WorkoutComplete : WorkoutState()
}

val WorkoutState.isPaused: Boolean get() = this is WorkoutState.Paused
