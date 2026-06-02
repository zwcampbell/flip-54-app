package com.flip54.core

import kotlinx.serialization.Serializable

@Serializable
enum class Difficulty {
    BEGINNER, STANDARD, ADVANCED;

    val multiplier: Double get() = when (this) {
        BEGINNER -> 0.5
        STANDARD -> 1.0
        ADVANCED -> 2.0
    }

    val displayName: String get() = when (this) {
        BEGINNER -> "Beginner"
        STANDARD -> "Standard"
        ADVANCED -> "Advanced"
    }
}
