package com.flip54.core

import org.junit.Assert.*
import org.junit.Test

class CardTest {

    @Test fun `standardDeck returns exactly 54 cards`() {
        assertEquals(54, Card.standardDeck().size)
    }

    @Test fun `standardDeck cards are all unique`() {
        val deck = Card.standardDeck()
        assertEquals(54, deck.toSet().size)
    }

    @Test fun `standardDeck contains 52 standard cards`() {
        val deck = Card.standardDeck()
        assertEquals(52, deck.filterIsInstance<Card.Standard>().size)
    }

    @Test fun `standardDeck contains 2 jokers`() {
        val deck = Card.standardDeck()
        assertEquals(2, deck.filterIsInstance<Card.Joker>().size)
    }

    @Test fun `standardDeck has 13 cards per suit`() {
        val deck = Card.standardDeck()
        for (suit in Suit.entries) {
            assertEquals("Expected 13 $suit cards", 13, deck.count { it.suit == suit })
        }
    }

    @Test fun `halfDeck returns exactly 27 cards`() {
        assertEquals(27, Card.halfDeck().size)
    }

    @Test fun `halfDeck contains exactly 1 joker`() {
        assertEquals(1, Card.halfDeck().filterIsInstance<Card.Joker>().size)
    }

    @Test fun `ace detection`() {
        assertTrue(Card.Standard(Suit.HEARTS, Rank.ACE).isAce)
        assertFalse(Card.Standard(Suit.HEARTS, Rank.TWO).isAce)
        assertFalse(Card.Joker(JokerVariant.RED).isAce)
    }

    @Test fun `face card detection`() {
        for (rank in listOf(Rank.JACK, Rank.QUEEN, Rank.KING)) {
            assertTrue(Card.Standard(Suit.HEARTS, rank).isFaceCard)
        }
        assertFalse(Card.Standard(Suit.HEARTS, Rank.TEN).isFaceCard)
    }

    @Test fun `pipValue correct for number cards`() {
        assertEquals(2, Rank.TWO.pipValue)
        assertEquals(5, Rank.FIVE.pipValue)
        assertEquals(10, Rank.TEN.pipValue)
    }

    @Test fun `pipValue null for face cards and ace`() {
        assertNull(Rank.JACK.pipValue)
        assertNull(Rank.QUEEN.pipValue)
        assertNull(Rank.KING.pipValue)
        assertNull(Rank.ACE.pipValue)
    }

    @Test fun `isFace correct`() {
        assertTrue(Rank.JACK.isFace)
        assertTrue(Rank.QUEEN.isFace)
        assertTrue(Rank.KING.isFace)
        assertFalse(Rank.ACE.isFace)
        assertFalse(Rank.TEN.isFace)
    }
}
