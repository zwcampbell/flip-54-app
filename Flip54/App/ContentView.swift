import SwiftUI
import SwiftData
import Flip54Core
import Flip54Storage
import Flip54WorkoutEngine

struct ContentView: View {
    @State private var coordinator = WorkoutCoordinator()
    @State private var completedData: CompletedWorkoutData?

    @Environment(\.modelContext) private var modelContext

    private var showCompletion: Bool { completedData != nil }

    private var isActiveWorkout: Bool {
        switch coordinator.state {
        case .idle, .shuffling: return false
        default: return true
        }
    }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            if let data = completedData {
                CompletionView(data: data) {
                    completedData = nil
                    coordinator = WorkoutCoordinator()
                }
                .transition(.opacity)
            } else if isActiveWorkout {
                ActiveWorkoutView(coordinator: coordinator) {
                    captureCompletion()
                }
                .transition(.opacity)
            } else {
                PreWorkoutView(coordinator: coordinator)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCompletion)
        .animation(.easeInOut(duration: 0.25), value: isActiveWorkout)
    }

    private func captureCompletion() {
        guard let session = coordinator.session else { return }
        completedData = CompletedWorkoutData(session: session, completedAt: Date())
        saveHistory(completedData!)
    }

    private func saveHistory(_ data: CompletedWorkoutData) {
        let history = WorkoutHistory(
            completedAt: data.completedAt,
            duration: data.duration,
            deckId: data.deckId,
            difficulty: data.difficulty,
            totalReps: data.totalReps,
            holdSecondsCompleted: data.holdSecondsCompleted,
            cardCount: data.cardCount,
            skipCount: data.skipCount,
            repsBySuit: data.repsBySuit,
            jumpingJacks: data.jumpingJacks
        )
        modelContext.insert(history)
        try? modelContext.save()
    }
}

// MARK: - Completed workout data snapshot

struct CompletedWorkoutData {
    let completedAt: Date
    let duration: TimeInterval
    let deckId: String
    let difficulty: Difficulty
    let totalReps: Int
    let holdSecondsCompleted: Int
    let cardCount: Int
    let skipCount: Int
    let repsBySuit: [Suit: Int]
    let jumpingJacks: Int

    init(session: ActiveSession, completedAt: Date) {
        self.completedAt = completedAt
        let elapsed = completedAt.timeIntervalSince(session.startedAt) - session.totalPausedDuration
        self.duration = max(0, elapsed)
        self.deckId = session.deckId
        self.difficulty = session.difficulty
        self.totalReps = session.totalRepsCompleted
        self.holdSecondsCompleted = session.holdSecondsCompleted
        self.cardCount = session.cardsCompleted
        self.skipCount = session.skipCount
        self.repsBySuit = session.repsBySuit
        let suitReps = session.repsBySuit.values.reduce(0, +)
        self.jumpingJacks = session.totalRepsCompleted - suitReps
    }
}
