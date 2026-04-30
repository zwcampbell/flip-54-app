import Foundation
import Testing
import Flip54Core
@testable import Flip54Storage

@Suite("ActiveSession")
struct ActiveSessionTests {

    private func makeSession() -> ActiveSession {
        var rng = SystemRandomNumberGenerator()
        return ActiveSession.start(
            deck: Card.standardDeck(),
            deckId: "standard",
            equipment: .bodyWeightOnly,
            difficulty: .standard,
            rng: &rng
        )
    }

    @Test("start creates 54-card draw pile")
    func startCreatesDeck() {
        let s = makeSession()
        #expect(s.drawPile.count == 54)
        #expect(s.currentCard == nil)
        #expect(s.discardPile.isEmpty)
        #expect(!s.isComplete)
    }

    @Test("cardsRemaining counts draw pile + current card")
    func cardsRemaining() {
        var s = makeSession()
        #expect(s.cardsRemaining == 54)
        s.flipNextCard()
        #expect(s.cardsRemaining == 54)  // still 54 while a card is active
    }

    @Test("flipNextCard moves top of draw pile to currentCard")
    func flipNextCard() {
        var s = makeSession()
        let top = s.drawPile.last!
        s.flipNextCard()
        #expect(s.currentCard == top)
        #expect(s.drawPile.count == 53)
    }

    @Test("flipNextCard is a no-op when card already face-up")
    func flipNoOpWhenFaceUp() {
        var s = makeSession()
        s.flipNextCard()
        let card = s.currentCard
        s.flipNextCard()  // should do nothing
        #expect(s.currentCard == card)
        #expect(s.drawPile.count == 53)
    }

    @Test("completeCurrentCard moves card to discard and logs reps")
    func completeCurrentCard() {
        var s = makeSession()
        s.flipNextCard()
        s.completeCurrentCard(reps: 7, holdSeconds: nil)
        #expect(s.currentCard == nil)
        #expect(s.discardPile.count == 1)
        #expect(s.totalRepsCompleted == 7)
        #expect(s.cardsCompleted == 1)
    }

    @Test("skipCurrentCard returns card to bottom of draw pile")
    func skipCurrentCard() {
        var s = makeSession()
        s.flipNextCard()
        let skipped = s.currentCard!
        s.skipCurrentCard()
        #expect(s.currentCard == nil)
        #expect(s.drawPile.first == skipped)  // index 0 = bottom
        #expect(s.skipCount == 1)
        #expect(s.drawPile.count == 54)  // deck size unchanged
        #expect(s.discardPile.isEmpty)
    }

    @Test("skip does not change cardsRemaining")
    func skipDoesNotChangeRemaining() {
        var s = makeSession()
        s.flipNextCard()
        #expect(s.cardsRemaining == 54)
        s.skipCurrentCard()
        #expect(s.cardsRemaining == 54)
    }

    @Test("pause/resume accumulates totalPausedDuration")
    func pauseResume() {
        var s = makeSession()
        let t0 = Date()
        s.pause(at: t0)
        #expect(s.pauseStartedAt == t0)
        let t1 = t0.addingTimeInterval(30)
        s.resume(at: t1)
        #expect(s.pauseStartedAt == nil)
        #expect(s.totalPausedDuration == 30)
    }

    @Test("pause during hold captures elapsed hold time")
    func pauseDuringHold() {
        var s = makeSession()
        // Force an ace card to be current
        s.drawPile = [.standard(suit: .hearts, rank: .ace)]
        s.flipNextCard()
        let holdStart = Date()
        s.startHold(at: holdStart)
        let pauseTime = holdStart.addingTimeInterval(20)
        s.pause(at: pauseTime)
        #expect(s.holdElapsed == 20)
        #expect(s.holdStartedAt == nil)
    }

    @Test("isComplete when draw pile empty and no current card")
    func isComplete() {
        var s = makeSession()
        s.drawPile = [.standard(suit: .hearts, rank: .two)]
        s.flipNextCard()
        #expect(!s.isComplete)
        s.completeCurrentCard(reps: 2, holdSeconds: nil)
        #expect(s.isComplete)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        var s = makeSession()
        s.flipNextCard()
        s.completeCurrentCard(reps: 5, holdSeconds: nil)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(ActiveSession.self, from: data)
        #expect(decoded == s)
    }

    @Test("repsBySuit accumulates correctly")
    func repsBySuit() {
        var s = makeSession()
        s.drawPile = [
            .standard(suit: .hearts, rank: .five),
            .standard(suit: .hearts, rank: .three),
        ]
        s.flipNextCard()
        s.completeCurrentCard(reps: 3, holdSeconds: nil)
        s.flipNextCard()
        s.completeCurrentCard(reps: 5, holdSeconds: nil)
        #expect(s.repsBySuit[.hearts] == 8)
    }
}
