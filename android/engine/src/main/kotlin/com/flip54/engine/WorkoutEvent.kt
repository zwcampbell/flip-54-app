package com.flip54.engine

sealed class WorkoutEvent {
    data object Shuffle : WorkoutEvent()
    data object ShuffleComplete : WorkoutEvent()
    data object FlipCard : WorkoutEvent()
    data object StartHold : WorkoutEvent()
    data object HoldTimerExpired : WorkoutEvent()
    data class MarkDone(val reps: Int?, val holdSeconds: Int?) : WorkoutEvent()
    data object Skip : WorkoutEvent()
    data object Pause : WorkoutEvent()
    data object Resume : WorkoutEvent()
    data object AdvanceComplete : WorkoutEvent()
}
