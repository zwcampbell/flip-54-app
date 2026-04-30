import Foundation
import Testing
@testable import Flip54Core

@Suite("Card")
struct CardTests {
    @Test("standardDeck returns exactly 54 cards")
    func standardDeckCount() {
        #expect(Card.standardDeck().count == 54)
    }

    @Test("standardDeck cards are all unique")
    func standardDeckUnique() {
        let deck = Card.standardDeck()
        let set = Set(deck)
        #expect(set.count == 54)
    }

    @Test("standardDeck contains 52 standard cards")
    func standardDeckHas52Standard() {
        let deck = Card.standardDeck()
        let standard = deck.filter { if case .standard = $0 { return true }; return false }
        #expect(standard.count == 52)
    }

    @Test("standardDeck contains 2 jokers")
    func standardDeckHas2Jokers() {
        let deck = Card.standardDeck()
        let jokers = deck.filter(\.isJoker)
        #expect(jokers.count == 2)
    }

    @Test("standardDeck has 13 cards per suit")
    func standardDeckPerSuit() {
        let deck = Card.standardDeck()
        for suit in Suit.allCases {
            let count = deck.filter { $0.suit == suit }.count
            #expect(count == 13, "Expected 13 \(suit) cards, got \(count)")
        }
    }

    @Test("Ace detection")
    func aceDetection() {
        #expect(Card.standard(suit: .hearts, rank: .ace).isAce)
        #expect(!Card.standard(suit: .hearts, rank: .two).isAce)
        #expect(!Card.joker(variant: .red).isAce)
    }

    @Test("Face card detection")
    func faceCardDetection() {
        for rank in [Rank.jack, .queen, .king] {
            #expect(Card.standard(suit: .hearts, rank: rank).isFaceCard)
        }
        #expect(!Card.standard(suit: .hearts, rank: .ten).isFaceCard)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let deck = Card.standardDeck()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(deck)
        let decoded = try decoder.decode([Card].self, from: data)
        #expect(decoded == deck)
    }
}

@Suite("Rank")
struct RankTests {
    @Test("pipValue is correct for number cards")
    func pipValues() {
        #expect(Rank.two.pipValue == 2)
        #expect(Rank.three.pipValue == 3)
        #expect(Rank.four.pipValue == 4)
        #expect(Rank.five.pipValue == 5)
        #expect(Rank.six.pipValue == 6)
        #expect(Rank.seven.pipValue == 7)
        #expect(Rank.eight.pipValue == 8)
        #expect(Rank.nine.pipValue == 9)
        #expect(Rank.ten.pipValue == 10)
    }

    @Test("pipValue is nil for face cards and Ace")
    func pipValueNilForSpecial() {
        #expect(Rank.jack.pipValue == nil)
        #expect(Rank.queen.pipValue == nil)
        #expect(Rank.king.pipValue == nil)
        #expect(Rank.ace.pipValue == nil)
    }

    @Test("isFace is correct")
    func isFaceCorrect() {
        #expect(Rank.jack.isFace)
        #expect(Rank.queen.isFace)
        #expect(Rank.king.isFace)
        #expect(!Rank.ace.isFace)
        #expect(!Rank.ten.isFace)
    }
}
