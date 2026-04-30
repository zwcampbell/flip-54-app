import Foundation
import Flip54Core

public struct ActiveSession: Codable, Hashable, Sendable {
    public let id: UUID
    public let deckId: String
    public let startedAt: Date
    public let equipment: Equipment
    public let difficulty: Difficulty

    public var drawPile: [Card]
    public var discardPile: [Card]
    public var currentCard: Card?

    public var totalRepsCompleted: Int
    public var holdSecondsCompleted: Int
    public var skipCount: Int
    public var cardsCompleted: Int
    public var repsBySuit: [Suit: Int]

    public var holdStartedAt: Date?
    public var holdElapsed: TimeInterval

    public var pauseStartedAt: Date?
    public var totalPausedDuration: TimeInterval

    public var cardsRemaining: Int {
        drawPile.count + (currentCard != nil ? 1 : 0)
    }

    public var isComplete: Bool {
        drawPile.isEmpty && currentCard == nil
    }

    // MARK: - Factory

    public static func start(
        deck: [Card],
        deckId: String,
        equipment: Equipment,
        difficulty: Difficulty,
        rng: inout some RandomNumberGenerator
    ) -> ActiveSession {
        var shuffled = deck
        shuffled.shuffle(using: &rng)
        return ActiveSession(
            id: UUID(),
            deckId: deckId,
            startedAt: Date(),
            equipment: equipment,
            difficulty: difficulty,
            drawPile: shuffled,
            discardPile: [],
            currentCard: nil,
            totalRepsCompleted: 0,
            holdSecondsCompleted: 0,
            skipCount: 0,
            cardsCompleted: 0,
            repsBySuit: [:],
            holdStartedAt: nil,
            holdElapsed: 0,
            pauseStartedAt: nil,
            totalPausedDuration: 0
        )
    }

    // MARK: - Mutations

    public mutating func flipNextCard() {
        guard currentCard == nil, !drawPile.isEmpty else { return }
        currentCard = drawPile.removeLast()
        holdElapsed = 0
        holdStartedAt = nil
    }

    public mutating func startHold(at date: Date) {
        guard let card = currentCard, card.isAce else { return }
        holdStartedAt = date
    }

    public mutating func completeCurrentCard(reps: Int?, holdSeconds: Int?) {
        guard let card = currentCard else { return }
        if let reps {
            totalRepsCompleted += reps
            if case .standard(let suit, _) = card {
                repsBySuit[suit, default: 0] += reps
            }
        }
        if let secs = holdSeconds {
            holdSecondsCompleted += secs
        }
        discardPile.append(card)
        cardsCompleted += 1
        currentCard = nil
        holdStartedAt = nil
        holdElapsed = 0
    }

    public mutating func skipCurrentCard() {
        guard let card = currentCard else { return }
        drawPile.insert(card, at: 0)  // bottom of draw pile (index 0 = bottom)
        skipCount += 1
        currentCard = nil
        holdStartedAt = nil
        holdElapsed = 0
    }

    public mutating func pause(at date: Date) {
        guard pauseStartedAt == nil else { return }
        pauseStartedAt = date
        if holdStartedAt != nil {
            holdElapsed += date.timeIntervalSince(holdStartedAt!)
            holdStartedAt = nil
        }
    }

    public mutating func resume(at date: Date) {
        guard let pauseStart = pauseStartedAt else { return }
        totalPausedDuration += date.timeIntervalSince(pauseStart)
        pauseStartedAt = nil
    }
}
