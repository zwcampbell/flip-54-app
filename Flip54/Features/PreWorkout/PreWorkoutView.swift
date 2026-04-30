import SwiftUI
import Flip54Core
import Flip54Storage
import Flip54WorkoutEngine

struct PreWorkoutView: View {
    let coordinator: WorkoutCoordinator
    let settings: UserSettings

    @Binding var showResumeBanner: Bool
    let onResume: () -> Void
    let onDismissResume: () -> Void

    /// Pass to show the "Try Tutorial" banner until the user has completed a tutorial flip.
    var onboardingState: OnboardingState? = nil
    /// Called when the user taps "Start Tutorial" from the banner.
    var onStartTutorial: (() -> Void)? = nil

    @State private var isShuffling = false
    @State private var shufflePhase: ShufflePhase = .idle
    @State private var showQuickRef = false
    @State private var tutorialBannerDismissed = false

    private enum ShufflePhase { case idle, spread, riffle, collapse }
    private let shuffleHaptic = UINotificationFeedbackGenerator()

    private var isShufflingState: Bool {
        if case .shuffling = coordinator.state { return true }
        return false
    }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if showResumeBanner {
                    resumeBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeOut(duration: 0.3), value: showResumeBanner)
                }
                if showTutorialBanner {
                    tutorialBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeOut(duration: 0.3), value: showTutorialBanner)
                }
                Spacer()
                deckFanView
                Spacer()
                difficultyBadge
                bottomBar
            }
        }
        .onChange(of: coordinator.state) { _, newState in
            if case .shuffling = newState {
                isShuffling = true
                shuffleHaptic.prepare()
                // Phase 1: spread (0-200ms)
                withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
                    shufflePhase = .spread
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    // Phase 2: riffle interleave (200-500ms)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
                        shufflePhase = .riffle
                    }
                    shuffleHaptic.notificationOccurred(.success)
                    try? await Task.sleep(for: .milliseconds(300))
                    // Phase 3: collapse to stack (500-700ms)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        shufflePhase = .collapse
                    }
                    try? await Task.sleep(for: .milliseconds(200))
                    coordinator.send(.shuffleComplete)
                    // Reset fan after transition to active workout
                    try? await Task.sleep(for: .milliseconds(400))
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        shufflePhase = .idle
                        isShuffling = false
                    }
                }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Standard Deck")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DS.Colors.bgCard)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(DS.Colors.border, lineWidth: 1))

            Spacer()

            Button { showQuickRef = true } label: {
                Text("?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.bgCard)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(DS.Colors.border, lineWidth: 1))
            }
            .sheet(isPresented: $showQuickRef) {
                QuickReferenceView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Resume banner

    private var resumeBanner: some View {
        HStack {
            Image(systemName: "arrow.clockwise")
                .foregroundStyle(DS.Colors.gold)
            Text("Resume your unfinished workout?")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            Button("Resume") { onResume() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.gold)
            Button {
                withAnimation { showResumeBanner = false }
                onDismissResume()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Colors.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DS.Colors.gold.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Tutorial banner

    private var showTutorialBanner: Bool {
        guard let ob = onboardingState else { return false }
        return !ob.hasCompletedTutorialFlip && !tutorialBannerDismissed
    }

    private var tutorialBanner: some View {
        HStack {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(DS.Colors.gold)
            Text("New? Try a tutorial flip first.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            Button("Start") {
                withAnimation { tutorialBannerDismissed = true }
                onStartTutorial?()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(DS.Colors.gold)
            Button {
                withAnimation { tutorialBannerDismissed = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Colors.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DS.Colors.gold.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Deck fan

    private struct CardOffset {
        let dx: CGFloat; let dy: CGFloat; let rot: Double
    }

    // Rest/fan positions
    private let fanOffsets: [CardOffset] = [
        CardOffset(dx: -28, dy: -6,  rot: -12),
        CardOffset(dx: -14, dy: -3,  rot:  -6),
        CardOffset(dx:   0, dy:  0,  rot:   0),
        CardOffset(dx:  14, dy: -3,  rot:   6),
        CardOffset(dx:  28, dy: -6,  rot:  12),
    ]

    // Spread positions (riffle phase — alternating L/R halves)
    private let riffleOffsets: [CardOffset] = [
        CardOffset(dx: -44, dy:  0, rot: -18),
        CardOffset(dx: -20, dy:  4, rot:  -8),
        CardOffset(dx:   0, dy:  8, rot:   0),
        CardOffset(dx:  20, dy:  4, rot:   8),
        CardOffset(dx:  44, dy:  0, rot:  18),
    ]

    private func currentOffset(for index: Int) -> CardOffset {
        let base   = fanOffsets[index]
        let riffle = riffleOffsets[index]
        switch shufflePhase {
        case .idle:     return base
        case .spread:   return CardOffset(dx: base.dx * 2.4, dy: base.dy * 2, rot: base.rot * 1.8)
        case .riffle:   return riffle
        case .collapse: return CardOffset(dx: 0, dy: 0, rot: 0)
        }
    }

    private var shuffleAnimationId: Int {
        switch shufflePhase {
        case .idle:     return 0
        case .spread:   return 1
        case .riffle:   return 2
        case .collapse: return 3
        }
    }

    private var deckFanView: some View {
        ZStack {
            ForEach(fanOffsets.indices, id: \.self) { i in
                let o = currentOffset(for: i)

                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [DS.Colors.bgCard, DS.Colors.bgRaised],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 196)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(DS.Colors.border, lineWidth: 1.5)
                    )
                    .overlay(
                        Text("54")
                            .font(.custom("BarlowCondensed-ExtraBold", size: 40))
                            .foregroundStyle(DS.Colors.gold)
                    )
                    .shadow(color: .black.opacity(shufflePhase == .collapse ? 0.9 : 0.6),
                            radius: shufflePhase == .collapse ? 24 : 12, x: 0, y: 6)
                    .offset(x: o.dx, y: o.dy)
                    .rotationEffect(.degrees(o.rot))
                    .animation(
                        .spring(response: 0.32, dampingFraction: 0.68)
                        .delay(Double(i) * 0.04),
                        value: shuffleAnimationId
                    )
                    .zIndex(Double(i))
            }
        }
        .frame(height: 260)
    }

    // MARK: - Difficulty badge

    private var difficultyBadge: some View {
        HStack(spacing: 6) {
            Text(settings.difficulty.displayName.uppercased())
                .font(.custom("Oswald-SemiBold", size: 11))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.2)
            Circle()
                .fill(DS.Colors.borderSub)
                .frame(width: 3, height: 3)
            Text(equipmentSummary)
                .font(.system(size: 11))
                .foregroundStyle(DS.Colors.textTertiary)
        }
        .padding(.bottom, 8)
    }

    private var equipmentSummary: String {
        var parts: [String] = []
        if settings.hasWeights    { parts.append("Weights") }
        if settings.hasPullUpBar  { parts.append("Pull-up bar") }
        if parts.isEmpty          { parts.append("Bodyweight") }
        return parts.joined(separator: " + ")
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button {
                // Configure coordinator with current settings before shuffle
                coordinator.configure(
                    equipment: settings.equipment,
                    difficulty: settings.difficulty,
                    deckId: settings.equippedDeckId
                )
                coordinator.send(.shuffle)
            } label: {
                Text(isShufflingState ? "SHUFFLING…" : "START")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                    .foregroundStyle(Color(hex: "#111111"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(DS.Colors.gold)
                    .clipShape(Capsule())
                    .shadow(color: DS.Colors.gold.opacity(0.25), radius: 12, x: 0, y: 0)
            }
            .disabled(isShufflingState)

            // Equipment for today link
            NavigationLink {
                // Settings is accessed via the Profile tab — this is a shortcut hint
                Text("Use the Profile tab to adjust settings.")
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding()
            } label: {
                Text("EQUIPMENT FOR TODAY")
                    .font(.custom("Oswald-SemiBold", size: 13))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .tracking(1.4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 52)
    }
}
