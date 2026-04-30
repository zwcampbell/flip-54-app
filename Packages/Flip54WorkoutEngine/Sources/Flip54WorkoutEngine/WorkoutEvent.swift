public enum WorkoutEvent: Sendable {
    case shuffle
    case shuffleComplete
    case flipCard
    case startHold
    case holdTimerExpired
    case markDone(reps: Int?, holdSeconds: Int?)
    case skip
    case pause
    case resume
    case advanceComplete
}
