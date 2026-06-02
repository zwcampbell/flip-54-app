package com.flip54.core

import kotlinx.serialization.Serializable

@Serializable
enum class Rank {
    TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN,
    JACK, QUEEN, KING, ACE;

    val pipValue: Int? get() = when (this) {
        TWO   -> 2
        THREE -> 3
        FOUR  -> 4
        FIVE  -> 5
        SIX   -> 6
        SEVEN -> 7
        EIGHT -> 8
        NINE  -> 9
        TEN   -> 10
        JACK, QUEEN, KING, ACE -> null
    }

    val isFace: Boolean get() = this == JACK || this == QUEEN || this == KING

    val displaySymbol: String get() = when (this) {
        TWO   -> "2"
        THREE -> "3"
        FOUR  -> "4"
        FIVE  -> "5"
        SIX   -> "6"
        SEVEN -> "7"
        EIGHT -> "8"
        NINE  -> "9"
        TEN   -> "10"
        JACK  -> "J"
        QUEEN -> "Q"
        KING  -> "K"
        ACE   -> "A"
    }
}
