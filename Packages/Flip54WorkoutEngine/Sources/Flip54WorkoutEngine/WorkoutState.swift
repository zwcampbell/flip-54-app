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
