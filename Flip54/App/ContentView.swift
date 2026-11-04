import SwiftUI
import SwiftData
import os.signpost
import Flip54Core
import Flip54DesignSystem
import Flip54Storage
import Flip54WorkoutEngine

private let saveLog = OSLog(subsystem: "com.flip54.app", category: "SwiftData")

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]
    @Query(sort: \WorkoutHistory.completedAt, order: .reverse) private var historyQuery: [WorkoutHistory]
    @Query private var onboardingQuery: [OnboardingState]
    @Query private var deckInventoryQuery: [DeckInventory]

    @State private var coordinator = WorkoutCoordinator()
    @Environment(WatchWorkoutLink.self) private var watchLink
    @State private var completedData: CompletedWorkoutData?
    @State private var showResumeBanner = false
    @State private var selectedTab = 0
    /// Runs a watch-followed workout while the app is in the background.
    @State private var watchRelay: WatchWorkoutRelay?

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
                    onEndEarly: captureEarlyHistory,
                    onboardingState: onboardingState,
                    isFirstWorkout: historyQuery.isEmpty
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
        .onChange(of: ObjectIdentifier(coordinator), initial: true) { _, _ in
            if watchRelay == nil {
                let relay = WatchWorkoutRelay(link: watchLink)
                relay.onEndEarly = captureEarlyHistory
                relay.onWorkoutComplete = captureCompletion
                watchRelay = relay
            }
            watchRelay?.attach(coordinator)
        }
        .onAppear {
            migrateDisabledExercisesIfNeeded()
            checkForResume()
            // Backfills unlocks for anyone who already qualified before this
            // shipped, and covers the (unlikely) case a prior award attempt
            // didn't persist.
            syncDeckUnlocks()
        }
        .onChange(of: coordinator.state) { old, new in syncWatch(from: old, to: new) }
        .onChange(of: coordinator.isHoldPausedInPlace) { _, _ in
            if coordinator.state != .idle, !coordinator.isTutorial {
                watchLink.update(coordinator.remoteSnapshot)
            }
        }
        // A workout from the watch can land in History while the app is open.
        .onChange(of: historyQuery.count) { _, _ in syncDeckUnlocks() }
        // Keep the watch's setup and deck unlocks in step with the iPhone's.
        .onChange(of: watchSettings, initial: true) { _, current in
            if let current { watchLink.phoneSettingsChanged(current) }
        }
        .onChange(of: isActiveWorkout) { wasActive, isActive in
            // When leaving an active workout (e.g., End Early), surface the
            // resume banner if a session is still persisted.
            if wasActive && !isActive {
                checkForResume()
            }
        }
        .injectReduceMotion()
    }

    // MARK: - Watch

    /// The setup and unlocks the watch should have, or nil before Settings exist.
    private var watchSettings: SyncedSettings? {
        guard let settings = settingsQuery.first else { return nil }
        let unlocked = Set(deckInventoryQuery.filter(\.isUnlocked).map(\.deckId)).union(["standard"])
        var toUnlock: [String: Int] = [:]
        for style in DeckCatalog.all {
            guard let threshold = style.unlockThreshold, threshold > 0, !unlocked.contains(style.id) else { continue }
            toUnlock[style.id] = max(0, threshold - historyQuery.count)
        }
        return SyncedSettings(difficulty: settings.difficulty, useHalfDeck: settings.useHalfDeck,
                              hasWeights: settings.hasWeights, hasPullUpBar: settings.hasPullUpBar,
                              deckId: settings.equippedDeckId, disabledExercises: settings.disabledExercises,
                              unlockedDeckIds: unlocked, workoutsToUnlock: toUnlock)
    }

    /// Keeps a paired watch in step with the deck: starting a workout launches
    /// the watch into it, each change is sent on, and ending tells it so.
    /// Tutorials stay on the iPhone.
    private func syncWatch(from old: WorkoutState, to new: WorkoutState) {
        if new == .idle {
            if old != .idle { watchLink.workoutEnded() }
            return
        }
        guard !coordinator.isTutorial else { return }
        if old == .idle {
            watchLink.workoutStarted(coordinator.remoteSnapshot)
        } else {
            watchLink.update(coordinator.remoteSnapshot)
        }
    }

    // MARK: - Onboarding completion

    private func handleOnboardingComplete(startTutorial: Bool) {
        onboardingState.hasSeenWelcome = true
        os_signpost(.begin, log: saveLog, name: "modelContext.save", "onboarding")
        try? modelContext.save()
        os_signpost(.end, log: saveLog, name: "modelContext.save", "onboarding")
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

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
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
            onDismissResume: dismissResume,
            onboardingState: onboardingState,
            onStartTutorial: startTutorialFromBanner
        )
    }

    private func startTutorialFromBanner() {
        coordinator.configureTutorial(
            equipment: settings.equipment,
            difficulty: settings.difficulty
        )
        coordinator.send(.shuffle)
    }

    // MARK: - History tab

    private var historyTab: some View {
        HistoryView(history: historyQuery)
    }

    // MARK: - Profile tab

    private var profileTab: some View {
        ProfileView(history: historyQuery)
    }

    // MARK: - Settings tab

    private var settingsTab: some View {
        SettingsView(settings: settings)
    }

    // MARK: - Completion

    private func captureCompletion() {
        // Once per workout: the background relay and the workout screen can
        // both report the same finish.
        guard completedData == nil, let session = coordinator.session else { return }
        let data = CompletedWorkoutData(session: session, completedAt: Date())
        completedData = data
        if coordinator.isTutorial {
            // Mark tutorial complete; don't save to history
            onboardingState.hasCompletedTutorialFlip = true
            os_signpost(.begin, log: saveLog, name: "modelContext.save", "tutorial-complete")
            try? modelContext.save()
            os_signpost(.end, log: saveLog, name: "modelContext.save", "tutorial-complete")
        } else {
            saveHistory(data)
        }
    }

    /// Records a partially completed workout in history. Returns true when a
    /// history entry was written so the caller can drop the persisted session
    /// instead of offering to resume (and later re-log) the same workout.
    private func captureEarlyHistory() -> Bool {
        guard !coordinator.isTutorial,
              let session = coordinator.session,
              session.cardsCompleted > 0 else { return false }
        let data = CompletedWorkoutData(session: session, completedAt: Date())
        saveHistory(data)
        return true
    }

    private func saveHistory(_ data: CompletedWorkoutData) {
        modelContext.insert(WorkoutHistory(data))
        os_signpost(.begin, log: saveLog, name: "modelContext.save", "workout-history")
        try? modelContext.save()
        os_signpost(.end, log: saveLog, name: "modelContext.save", "workout-history")
        syncDeckUnlocks()
    }

    // MARK: - Deck unlocks

    /// Awards any deck whose unlock threshold is now met a persisted
    /// DeckInventory row. Unlocking is one-way and sticky: once earned, a
    /// deck stays unlocked even if the user later deletes workout history
    /// that would otherwise put them back under the threshold.
    private func syncDeckUnlocks() {
        let totalWorkouts = (try? modelContext.fetchCount(FetchDescriptor<WorkoutHistory>())) ?? historyQuery.count
        // Read the raw query rather than the `settings` convenience getter,
        // which inserts a default UserSettings as a side effect — harmless
        // normally, but not something this background sync should trigger.
        let equippedDeckId = settingsQuery.first?.equippedDeckId
        for style in DeckCatalog.all {
            guard let threshold = style.unlockThreshold, threshold > 0 else { continue }
            // Grandfather in a deck the user already has equipped, so
            // introducing or raising a threshold never locks someone out of
            // what they're already using.
            let qualifies = totalWorkouts >= threshold || equippedDeckId == style.id
            guard qualifies else { continue }
            if let existing = deckInventoryQuery.first(where: { $0.deckId == style.id }) {
                if existing.unlockedAt == nil { existing.unlockedAt = Date() }
            } else {
                modelContext.insert(DeckInventory(deckId: style.id, unlockedAt: Date()))
            }
        }
        try? modelContext.save()
    }

    // MARK: - One-time settings migration

    /// Disabled-exercise toggles used to live in raw UserDefaults; they now
    /// live on UserSettings alongside the rest of the workout configuration.
    /// Copy any pre-existing value over exactly once so upgrading users don't
    /// lose their exercise toggles.
    private func migrateDisabledExercisesIfNeeded() {
        let migrationFlagKey = "hasMigratedDisabledExercisesToSwiftData"
        guard !UserDefaults.standard.bool(forKey: migrationFlagKey) else { return }
        if let legacy = UserDefaults.standard.string(forKey: UserDefaultsKeys.disabledExercises),
           !legacy.isEmpty {
            settings.disabledExercisesRaw = legacy
        }
        UserDefaults.standard.set(true, forKey: migrationFlagKey)
    }

    // MARK: - Resume support

    private func checkForResume() {
        let store = ActiveSessionStore()
        // Also clears the banner once nothing's left to resume (e.g. the
        // workout it offered was started fresh and then ended).
        if let saved = store.load(),
           !saved.isComplete,
           Date().timeIntervalSince(saved.startedAt) < 86400 {
            showResumeBanner = true
        } else {
            showResumeBanner = false
        }
    }

    private func resumeSession() {
        showResumeBanner = false
        coordinator.restoreIfNeeded()
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
