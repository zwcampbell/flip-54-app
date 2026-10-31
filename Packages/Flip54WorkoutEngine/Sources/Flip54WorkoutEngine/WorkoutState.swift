import Foundation
import Flip54Core

public indirect enum WorkoutState: Codable, Equatable, Sendable {
    case idle
    case shuffling
    case cardFaceDown
    case cardFaceUp(card: Card, prescription: Prescription)
    case holdStarting(card: Card)
    case holding(card: Card, startTime: Date, durationSeconds: Int)
    case holdComplete(card: Card, secondsHeld: Int, completedFully: Bool)
    case cardCompleting(card: Card)
    case cardSkipping(card: Card)
    case paused(previous: WorkoutState)
    case workoutComplete
}

extension WorkoutState {
    /// The Ace hold a pause interrupted, if the workout was paused mid-hold.
    public var pausedHold: (card: Card, durationSeconds: Int)? {
        guard case .paused(let previous) = self,
              case .holding(let card, _, let duration) = previous else { return nil }
        return (card, duration)
    }
}
