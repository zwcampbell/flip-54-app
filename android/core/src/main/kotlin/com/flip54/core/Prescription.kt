package com.flip54.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed class Prescription {
    @Serializable
    @SerialName("reps")
    data class Reps(val exercise: Exercise, val count: Int) : Prescription()

    @Serializable
    @SerialName("hold")
    data class Hold(val exercise: Exercise, val seconds: Int) : Prescription()

    val exercise: Exercise get() = when (this) {
        is Reps -> exercise
        is Hold -> exercise
    }

    val isHold: Boolean get() = this is Hold

    val displayString: String get() = when (this) {
        is Reps -> "${exercise.displayName} · $count reps"
        is Hold -> {
            val mins = seconds / 60
            val secs = seconds % 60
            val secsStr = if (secs < 10) "0$secs" else "$secs"
            val timeStr = if (mins > 0) "$mins:$secsStr" else "${secs}s"
            "${exercise.displayName} · Hold for $timeStr"
        }
    }
}
