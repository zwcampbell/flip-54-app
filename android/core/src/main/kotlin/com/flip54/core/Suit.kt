package com.flip54.core

import kotlinx.serialization.Serializable

@Serializable
enum class Suit {
    HEARTS, SPADES, CLUBS, DIAMONDS;

    val color: SuitColor get() = when (this) {
        HEARTS, DIAMONDS -> SuitColor.RED
        SPADES, CLUBS    -> SuitColor.BLACK
    }
}

@Serializable
enum class SuitColor { RED, BLACK }
