import SwiftUI
import SwiftData
import Flip54Core
import Flip54Storage
import Flip54WorkoutEngine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]
    @Query(sort: \WorkoutHistory.completedAt, order: .reverse) private var historyQuery: [WorkoutHistory]
    @Query private var onboardingQuery: [OnboardingState]

    @State private var coordinator = WorkoutCoordinator()
    @State private var completedData: CompletedWorkoutData?
    @State private var showResumeBanner = false
    @State private var selectedTab = 0

    // Convenience: always-valid settings (creates default on first run)
    private var settings: UserSettings {
        if let s = settingsQuery.first { return s }
        let s = UserSettings()
        modelContext.insert(s)
        return s
    }

    // Convenience: always-valid onboarding state
    private var onboardingState: OnboardingState {
        if let o = onboardingQuery.first { return o }
        let o = OnboardingState()
        modelContext.insert(o)
        return o
    }

    private var showOnboarding: Bool {
        onboardingQuery.isEmpty || !onboardingQuery[0].hasSeenWelcome
    }

    private var showCompletion: Bool { completedData != nil }

    private var isActiveWorkout: Bool {
        switch coordinator.state {
        case .idle, .shuffling: return false
        default: return true
        }
    }

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(
                    state: onboardingState,
                    settings: settings,
                    onComplete: handleOnboardingComplete
                )
                .transition(.opacity)
                .zIndex(3)
            } else if let data = completedData {
                CompletionView(data: data) {
                    completedData = nil
                    coordinator = WorkoutCoordinator()
                }
                .transition(.opacity)
                .zIndex(2)
            } else if isActiveWorkout {
                ActiveWorkoutView(
                    coordinator: coordinator,
                    onWorkoutComplete: captureCompletion,
                    onboardingState: onboardingState
                )
                .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                .zIndex(1)
            } else {
                mainTabView
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showOnboarding)
        .animation(.easeInOut(duration: 0.22), value: showCompletion)
        .animation(.easeInOut(duration: 0.22), value: isActiveWorkout)
        .onAppear { checkForResume() }
    }

    // MARK: - Onboarding completion

    private func handleOnboardingComplete(startTutorial: Bool) {
        onboardingState.hasSeenWelcome = true
        try? modelContext.save()
        if startTutorial {
            coordinator.configureTutorial(
                equipment: settings.equipment,
                difficulty: settings.difficulty
            )
            coordinator.send(.shuffle)
        }
    }

    // MARK: - Tab view

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            workoutTab
                .tabItem {
                    Label("Workout", systemImage: "suit.club.fill")
                }
                .tag(0)

            historyTab
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)

            profileTab
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .tint(DS.Colors.gold)
        .onAppear { applyTabBarAppearance() }
    }

    // MARK: - Workout tab

    private var workoutTab: some View {
        PreWorkoutView(
            coordinator: coordinator,
            settings: settings,
            showResumeBanner: $showResumeBanner,
            onResume: resumeSession,
            onDismissResume: dismissResume
        )
    }

    // MARK: - History tab

    private var historyTab: some View {
        HistoryView(history: historyQuery)
    }

    // MARK: - Profile tab

    private var profileTab: some View {
        ProfileView(history: historyQuery, settings: settings)
    }

    // MARK: - Completion

    private func captureCompletion() {
        guard let session = coordinator.session else { return }
        let data = CompletedWorkoutData(session: session, completedAt: Date())
        completedData = data
        if coordinator.isTutorial {
            // Mark tutorial complete; don't save to history
            onboardingState.hasCompletedTutorialFlip = true
            try? modelContext.save()
        } else {
            saveHistory(data)
        }
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

    // MARK: - Resume support

    private func checkForResume() {
        let store = ActiveSessionStore()
        if let saved = store.load(),
           !saved.isComplete,
           Date().timeIntervalSince(saved.startedAt) < 86400 {
            showResumeBanner = true
        }
    }

    private func resumeSession() {
        showResumeBanner = false
        coordinator.restoreIfNeeded(
            equipment: settings.equipment,
            difficulty: settings.difficulty,
            deckId: settings.equippedDeckId
        )
    }

    private func dismissResume() {
        showResumeBanner = false
        ActiveSessionStore().clear()
    }

    // MARK: - Tab bar appearance

    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DS.Colors.bgRaised)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DS.Colors.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(DS.Colors.textTertiary)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
