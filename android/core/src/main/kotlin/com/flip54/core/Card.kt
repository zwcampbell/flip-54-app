package com.flip54.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed class Card {
    @Serializable
    @SerialName("standard")
    data class Standard(val suit: Suit, val rank: Rank) : Card()

    @Serializable
    @SerialName("joker")
    data class Joker(val variant: JokerVariant) : Card()

    val isAce: Boolean get() = this is Standard && rank == Rank.ACE
    val isJoker: Boolean get() = this is Joker
    val isFaceCard: Boolean get() = this is Standard && rank.isFace
    val suit: Suit? get() = (this as? Standard)?.suit

    companion object {
        fun standardDeck(): List<Card> = buildList {
            for (suit in Suit.entries) {
                for (rank in Rank.entries) {
                    add(Standard(suit, rank))
                }
            }
            add(Joker(JokerVariant.RED))
            add(Joker(JokerVariant.BLACK))
        }

        fun halfDeck(): List<Card> {
            val topRanks = listOf(Rank.ACE, Rank.KING, Rank.QUEEN, Rank.JACK, Rank.TEN, Rank.NINE)
            return buildList {
                for (suit in Suit.entries) {
                    for (rank in topRanks) {
                        add(Standard(suit, rank))
                    }
                }
                add(Standard(Suit.HEARTS, Rank.EIGHT))
                add(Standard(Suit.SPADES, Rank.EIGHT))
                add(Joker(JokerVariant.RED))
            }
        }
    }
}

@Serializable
enum class JokerVariant { RED, BLACK }
