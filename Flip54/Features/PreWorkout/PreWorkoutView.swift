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
    @State private var showSettings = false
    @State private var scatterOffsets: [CardOffset] = []

    private enum ShufflePhase { case idle, spread, scatter, collapse }

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
        .sheet(isPresented: $showSettings) {
            PreWorkoutSettingsSheet(settings: settings)
        }
        .onChange(of: coordinator.state) { _, newState in
            if case .shuffling = newState {
                isShuffling = true
                // Phase 1: spread out (0-150ms)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                    shufflePhase = .spread
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    // Phase 2: scatter — cards explode to random positions
                    // (150-650ms). Re-roll offsets so every shuffle looks
                    // different.
                    scatterOffsets = makeScatterOffsets()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                        shufflePhase = .scatter
                    }
                    HapticEngine.shared.play(.shuffle)
                    SoundPlayer.shared.play(.deckRiffle)
                    try? await Task.sleep(for: .milliseconds(280))
                    // Mid-scatter: re-roll for a second burst of chaos
                    scatterOffsets = makeScatterOffsets()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                        // Force re-evaluation of currentOffset by toggling phase
                        // through a temporary spread back into scatter.
                        shufflePhase = .spread
                    }
                    try? await Task.sleep(for: .milliseconds(80))
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.55)) {
                        shufflePhase = .scatter
                    }
                    try? await Task.sleep(for: .milliseconds(220))
                    // Phase 3: collapse to stack
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        shufflePhase = .collapse
                    }
                    try? await Task.sleep(for: .milliseconds(220))
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
        CardOffset(dx: -32, dy: -8,  rot: -14),
        CardOffset(dx: -22, dy: -5,  rot: -10),
        CardOffset(dx: -12, dy: -2,  rot:  -6),
        CardOffset(dx:  -4, dy:  0,  rot:  -2),
        CardOffset(dx:   0, dy:  0,  rot:   0),
        CardOffset(dx:   4, dy:  0,  rot:   2),
        CardOffset(dx:  12, dy: -2,  rot:   6),
        CardOffset(dx:  22, dy: -5,  rot:  10),
        CardOffset(dx:  32, dy: -8,  rot:  14),
    ]

    /// Random positions for the scatter phase. Re-rolled each shuffle so the
    /// animation never looks identical twice.
    private func makeScatterOffsets() -> [CardOffset] {
        (0..<fanOffsets.count).map { _ in
            CardOffset(
                dx: CGFloat.random(in: -200...200),
                dy: CGFloat.random(in: -180...180),
                rot: Double.random(in: -540...540)
            )
        }
    }

    private func currentOffset(for index: Int) -> CardOffset {
        let base = fanOffsets[index]
        switch shufflePhase {
        case .idle:     return base
        case .spread:   return CardOffset(dx: base.dx * 2.4, dy: base.dy * 2, rot: base.rot * 1.8)
        case .scatter:
            return scatterOffsets.indices.contains(index) ? scatterOffsets[index] : base
        case .collapse: return CardOffset(dx: 0, dy: 0, rot: 0)
        }
    }

    private var shuffleAnimationId: Int {
        switch shufflePhase {
        case .idle:     return 0
        case .spread:   return 1
        case .scatter:  return 2
        case .collapse: return 3
        }
    }

    private var deckFanView: some View {
        ZStack {
            ForEach(fanOffsets.indices, id: \.self) { i in
                let o = currentOffset(for: i)
                fanCard
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

    private var fanCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1A1A22"), Color(hex: "#0E0E16")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(DS.Colors.border, lineWidth: 1.5)

            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DS.Colors.border.opacity(0.5), lineWidth: 1)
                .padding(8)

            Circle()
                .strokeBorder(DS.Colors.gold.opacity(0.4), lineWidth: 1.5)
                .frame(width: 56, height: 56)

            Text("54")
                .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                .foregroundStyle(DS.Colors.gold)

            fanCornerDots
        }
        .frame(width: 140, height: 196)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var fanCornerDots: some View {
        GeometryReader { geo in
            let inset: CGFloat = 11
            let dotSize: CGFloat = 4
            Group {
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: inset, y: inset)
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: geo.size.width - inset, y: inset)
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: inset, y: geo.size.height - inset)
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: geo.size.width - inset, y: geo.size.height - inset)
            }
        }
    }

    // MARK: - Difficulty badge

    private var difficultyBadge: some View {
        HStack(spacing: 12) {
            settingColumn(
                label: "DIFFICULTY",
                value: settings.difficulty.displayName.uppercased()
            )
            settingColumn(
                label: "EQUIPMENT",
                value: equipmentSummary.uppercased()
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func settingColumn(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.custom("Oswald-SemiBold", size: 10))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.4)
            settingPill(text: value)
        }
    }

    private func settingPill(text: String) -> some View {
        Button {
            showSettings = true
        } label: {
            Text(text)
                .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                .foregroundStyle(DS.Colors.textPrimary)
                .tracking(1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(DS.Colors.bgCard)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(DS.Colors.border, lineWidth: 1))
        }
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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 52)
    }
}

// MARK: - Settings sheet wrapper

private struct PreWorkoutSettingsSheet: View {
    @Bindable var settings: UserSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.gold)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                SettingsView(settings: settings)
            }
        }
    }
}
