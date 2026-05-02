import SwiftUI
import Flip54Core
import Flip54Storage
import Flip54WorkoutEngine

struct ActiveWorkoutView: View {
    let coordinator: WorkoutCoordinator
    let onWorkoutComplete: () -> Void
    /// Pass the live OnboardingState to enable first-time contextual tooltips.
    /// Nil disables all tooltips.
    var onboardingState: OnboardingState? = nil
    /// True when this is the user's first workout (no completed workouts in history).
    /// Tooltips only show when this is true.
    var isFirstWorkout: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Card flip animation — 3D Y-axis rotation (or cross-fade when reduceMotion=true)
    @State private var flipDegrees: Double = 0        // 0 = face-down, 180 = face-up
    @State private var flipScale: CGFloat = 1         // subtle mid-flip scale pulse
    @State private var isFlipping = false

    // Card position / exit animation
    @State private var cardOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1
    @State private var cardTilt: Double = 0     // Z-axis rotation (degrees)
    @State private var cardZIndex: Double = 1   // 1 = above deck, -1 = behind deck

    // Card enter animation
    @State private var showPrescription = false

    private let haptic = HapticEngine.shared

    // First-time contextual tooltip
    @State private var activeTooltip: TooltipKind? = nil

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                workoutBar
                cardArea
                actionArea
            }
            if isPaused {
                pauseOverlay
            }
            if let tip = activeTooltip {
                tooltipOverlay(tip)
            }
        }
        .onChange(of: coordinator.state) { _, newState in
            handleStateChange(newState)
        }
    }

    // MARK: - Derived state

    private var cardsRemaining: Int {
        coordinator.session?.cardsRemaining ?? 54
    }

    private var cardsCompleted: Int {
        coordinator.session?.cardsCompleted ?? 0
    }

    private var isPaused: Bool {
        if case .paused = coordinator.state { return true }
        return false
    }

    private var isFaceUp: Bool {
        switch coordinator.state {
        case .cardFaceUp, .holdStarting, .holding, .holdComplete: return true
        default: return false
        }
    }

    private var currentCard: Card? {
        switch coordinator.state {
        case .cardFaceUp(let card, _): return card
        case .holdStarting(let card): return card
        case .holding(let card, _, _): return card
        case .holdComplete(let card, _, _): return card
        case .cardCompleting(let card): return card
        case .cardSkipping(let card): return card
        default: return coordinator.session?.currentCard
        }
    }

    private var currentPrescription: Prescription? {
        if case .cardFaceUp(_, let p) = coordinator.state { return p }
        return nil
    }

    // MARK: - Workout bar

    private var workoutBar: some View {
        let total = 54
        let done = cardsCompleted
        let pct = total > 0 ? Double(done) / Double(total) : 0

        return HStack(spacing: 0) {
            // Left: progress ring
            ZStack {
                Circle()
                    .stroke(DS.Colors.bgRaised, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: done)
                Text("\(done)")
                    .font(.custom("IBMPlexMono-Medium", size: 12))
                    .foregroundStyle(DS.Colors.textPrimary)
            }
            .frame(width: 52, height: 52)

            Spacer()

            // Center: cards remaining
            VStack(spacing: 1) {
                Text("CARDS REMAINING")
                    .font(.custom("Oswald-SemiBold", size: 10))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .tracking(1.2)
                Text("\(cardsRemaining)")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            Spacer()

            // Right: pause
            Button {
                coordinator.send(.pause)
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(DS.Colors.bgRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(DS.Colors.border, lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider().background(DS.Colors.borderSub)
        }
    }

    // MARK: - Card area

    private var cardArea: some View {
        VStack(spacing: 20) {
            // Card + deck-stack indicator behind it
            ZStack {
                deckStackIndicator
                    .zIndex(0)
                Group {
                    if let card = currentCard {
                        CardView(card: card, faceUp: isFaceUp,
                                 deckId: coordinator.session?.deckId ?? "standard")
                    } else {
                        CardView(card: .standard(suit: .hearts, rank: .two), faceUp: false)
                    }
                }
                // 3D flip + Z-axis tilt for swipe; scaleEffect = mid-flip size pulse
                .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .rotationEffect(.degrees(cardTilt))
                .scaleEffect(flipScale)
                .offset(cardOffset)
                .opacity(cardOpacity)
                .zIndex(cardZIndex)
                .onTapGesture {
                    if case .cardFaceDown = coordinator.state { handleFlipTap() }
                }
                .gesture(swipeGesture)
            }

            // Prescription / prompt
            prescriptionArea
                .frame(height: 130)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DS.Layout.horizontalMargin)
    }

    // MARK: - Swipe gesture

    private var canSwipe: Bool {
        switch coordinator.state {
        case .cardFaceUp(_, let p): return !p.isHold
        case .holdComplete:         return true
        default:                    return false
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard canSwipe else { return }
                cardOffset = CGSize(
                    width: value.translation.width,
                    height: value.translation.height * 0.4
                )
                cardTilt = Double(value.translation.width / 18)
            }
            .onEnded { value in
                guard canSwipe else {
                    springBackCard()
                    return
                }
                let threshold: CGFloat = 100
                if value.translation.width > threshold {
                    if case .holdComplete = coordinator.state {
                        coordinator.send(.advanceComplete)
                        handleCardAdvance()
                    } else {
                        handleDone()
                    }
                } else if value.translation.width < -threshold {
                    handleSkip()
                } else {
                    springBackCard()
                }
            }
    }

    private func springBackCard() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            cardOffset = .zero
            cardTilt = 0
        }
    }

    // MARK: - Deck stack indicator

    /// Three thin card shapes stacked behind the active card, shrinking as cards are depleted.
    private var deckStackIndicator: some View {
        let remaining = coordinator.session?.cardsRemaining ?? 54
        let total = 54
        let fraction = total > 0 ? Double(remaining) / Double(total) : 0
        // Show 0–3 shadow cards based on remaining fraction
        let layers = fraction > 0.66 ? 3 : fraction > 0.33 ? 2 : fraction > 0 ? 1 : 0

        return ZStack {
            ForEach(0..<3, id: \.self) { idx in
                if idx < layers {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.bgCard, DS.Colors.bgRaised],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: CardView.cardWidth  - CGFloat(idx + 1) * 4,
                            height: CardView.cardHeight - CGFloat(idx + 1) * 4
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(DS.Colors.border.opacity(0.6 - Double(idx) * 0.15), lineWidth: 1)
                        )
                        .offset(y: CGFloat(idx + 1) * 5)
                        .zIndex(-Double(idx + 1))
                        .opacity(0.6 - Double(idx) * 0.15)
                } else {
                    Color.clear
                        .frame(width: CardView.cardWidth, height: CardView.cardHeight)
                        .zIndex(-Double(idx + 1))
                }
            }
        }
        .animation(.easeOut(duration: 0.5), value: layers)
    }

    @ViewBuilder
    private var prescriptionArea: some View {
        switch coordinator.state {
        case .cardFaceDown:
            Text("TAP TO FLIP")
                .font(.custom("Oswald-SemiBold", size: 13))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.4)

        case .cardFaceUp(_, let prescription):
            VStack(spacing: 8) {
                Text(prescription.exercise.displayName.uppercased())
                    .font(.custom("Oswald-SemiBold", size: 17))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .tracking(1.0)

                if case .reps(let exercise, let count) = prescription {
                    let isRed = isRedCard
                    let isJoker = exercise == .jumpingJacks
                    Text("\(count) reps")
                        .font(.custom("BarlowCondensed-ExtraBold", size: 52))
                        .foregroundStyle(isRed && !isJoker ? DS.Colors.red : DS.Colors.gold)
                }
            }
            .transition(.opacity.combined(with: .offset(y: 8)))
            .animation(.easeOut(duration: 0.25), value: showPrescription)

        case .holding(let card, let startTime, let durationSeconds):
            HoldTimerView(startTime: startTime, durationSeconds: durationSeconds)
                .transition(.opacity)

        case .holdStarting:
            HoldTimerView(startTime: Date(), durationSeconds: 60)

        case .holdComplete(_, let secs, let full):
            holdCompleteView(secondsHeld: secs, completedFully: full)

        default:
            Color.clear
        }
    }

    private var isRedCard: Bool {
        guard let card = currentCard else { return false }
        if case .standard(let suit, _) = card {
            return suit == .hearts || suit == .diamonds
        }
        return false
    }

    // MARK: - Hold complete

    private func holdCompleteView(secondsHeld: Int, completedFully: Bool) -> some View {
        AnimatedCheckmarkRing(size: 110, lineWidth: 7, color: DS.Colors.success)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Action area

    @ViewBuilder
    private var actionArea: some View {
        VStack(spacing: 10) {
            switch coordinator.state {
            case .cardFaceDown:
                flipButton

            case .cardFaceUp(_, let prescription):
                primaryButton(label: prescription.isHold ? "START HOLD" : "DONE") {
                    if prescription.isHold {
                        coordinator.send(.startHold)
                    } else {
                        handleDone()
                    }
                }
                skipButton

            case .holding:
                holdingButton
                skipButton

            case .holdComplete:
                primaryButton(label: "DONE") {
                    coordinator.send(.advanceComplete)
                    handleCardAdvance()
                }

            default:
                Color.clear.frame(height: 64)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 52)
        .animation(.easeInOut(duration: 0.2), value: statePhaseKey)
    }

    // Used to animate action area transitions
    private var statePhaseKey: Int {
        switch coordinator.state {
        case .cardFaceDown:    return 0
        case .cardFaceUp:      return 1
        case .holding:         return 2
        case .holdComplete:    return 3
        default:               return 4
        }
    }

    private var flipButton: some View {
        Button { handleFlipTap() } label: {
            Text("FLIP CARD")
                .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                .foregroundStyle(DS.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(DS.Colors.bgRaised)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(DS.Colors.border, lineWidth: 1.5))
        }
    }

    private var holdingButton: some View {
        Text("HOLDING…")
            .font(.custom("BarlowCondensed-ExtraBold", size: 26))
            .foregroundStyle(Color(hex: "#111111"))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(DS.Colors.gold)
            .overlay(ShimmerOverlay())
            .clipShape(Capsule())
            .shadow(color: DS.Colors.gold.opacity(0.25), radius: 12)
    }

    private func primaryButton(label: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                .foregroundStyle(Color(hex: "#111111"))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(enabled ? DS.Colors.gold : DS.Colors.gold.opacity(0.5))
                .clipShape(Capsule())
                .shadow(color: DS.Colors.gold.opacity(0.2), radius: 12)
        }
        .disabled(!enabled)
    }

    private var skipButton: some View {
        Button {
            handleSkip()
        } label: {
            Text("SKIP")
                .font(.custom("Oswald-SemiBold", size: 14))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.2)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
    }

    // MARK: - Pause overlay

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()
            VStack(spacing: 40) {
                Text("PAUSED")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 80))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(4)

                VStack(spacing: 12) {
                    Button {
                        coordinator.send(.resume)
                    } label: {
                        Text("RESUME")
                            .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                            .foregroundStyle(Color(hex: "#111111"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(DS.Colors.gold)
                            .clipShape(Capsule())
                    }

                    Button {
                        coordinator.send(.resume)
                        // TODO: end early and save partial
                    } label: {
                        Text("END EARLY")
                            .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                            .foregroundStyle(DS.Colors.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color.clear)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(DS.Colors.red, lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isPaused)
    }

    // MARK: - Actions

    private func handleFlipTap() {
        guard !isFlipping else { return }
        isFlipping = true
        showPrescription = false

        if reduceMotion {
            // Reduced motion: simple cross-fade, no rotation
            withAnimation(.easeInOut(duration: 0.18)) { cardOpacity = 0 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                coordinator.send(.flipCard)
                haptic.play(.cardFlip)
                SoundPlayer.shared.play(.cardFlip)
                if let card = coordinator.session?.currentCard {
                    UIAccessibility.post(notification: .announcement, argument: card.accessibilityLabel)
                }
                withAnimation(.easeInOut(duration: 0.18)) { cardOpacity = 1 }
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeOut(duration: 0.15)) { showPrescription = true }
                isFlipping = false
            }
        } else {
            // Phase 1: rotate to 90° (card edge-on) — ease-in 0.2s
            withAnimation(.easeIn(duration: 0.20)) {
                flipDegrees = 90
                flipScale = 0.92
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                // At edge-on, swap state to face-up AND snap rotation to -90°
                // (also edge-on — the swap is invisible). This avoids ending
                // the animation at 180° where the face would render mirrored.
                coordinator.send(.flipCard)
                haptic.play(.cardFlip)
                SoundPlayer.shared.play(.cardFlip)
                flipDegrees = -90
                // Phase 2: -90° → 0° brings the front face flat, unmirrored
                withAnimation(.easeOut(duration: 0.22)) {
                    flipDegrees = 0
                    flipScale = 1
                }
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.2)) { showPrescription = true }
                isFlipping = false
                if let card = coordinator.session?.currentCard {
                    UIAccessibility.post(notification: .announcement, argument: card.accessibilityLabel)
                }
            }
        }
    }

    private func handleDone() {
        haptic.play(.done)
        coordinator.send(.markDone(reps: nil, holdSeconds: nil))
        // .cardCompleting is handled in onChange
    }

    private func handleSkip() {
        haptic.play(.skip)
        SoundPlayer.shared.play(.cardSkip, volume: 0.6)
        coordinator.send(.skip)
        // .cardSkipping is handled in onChange
    }

    private func handleCardAdvance() {
        // Used after .holdComplete DONE — fly off to the right.
        showPrescription = false
        cardZIndex = 1
        withAnimation(.easeIn(duration: 0.32)) {
            cardOffset = CGSize(width: 500, height: 24)
            cardTilt = 16
            cardOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            cardOffset = .zero
            cardTilt = 0
            cardOpacity = 1
        }
    }

    private func handleStateChange(_ newState: WorkoutState) {
        switch newState {
        case .holdStarting:
            haptic.play(.holdStart)
            SoundPlayer.shared.play(.holdStart)
            coordinator.send(.startHold)

        case .cardFaceUp(let card, _):
            checkTooltip(for: card)

        case .cardCompleting:
            // Fly off to the right (above the deck), out of frame.
            activeTooltip = nil
            showPrescription = false
            flipDegrees = 0
            flipScale = 1
            cardZIndex = 1
            withAnimation(.easeIn(duration: 0.35)) {
                cardOffset = CGSize(width: 500, height: 30)
                cardTilt = 18
                cardOpacity = 0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                coordinator.send(.advanceComplete)
                cardOffset = .zero
                cardTilt = 0
                cardOpacity = 1
            }

        case .cardSkipping:
            // Slide off to the LEFT, behind the deck (returns to bottom of pile).
            activeTooltip = nil
            showPrescription = false
            flipDegrees = 0
            flipScale = 1
            cardZIndex = -1
            withAnimation(.easeIn(duration: 0.40)) {
                cardOffset = CGSize(width: -500, height: 40)
                cardTilt = -14
                cardOpacity = 0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                coordinator.send(.advanceComplete)
                cardOffset = .zero
                cardTilt = 0
                cardOpacity = 1
                cardZIndex = 1
            }

        case .workoutComplete:
            SoundPlayer.shared.play(.completion)
            onWorkoutComplete()

        default:
            break
        }
    }

    // MARK: - Contextual tooltip logic

    private func checkTooltip(for card: Card) {
        guard isFirstWorkout, let ob = onboardingState else { return }
        if card.isAce, !ob.seenAceTooltip {
            withAnimation(.spring(response: 0.4)) { activeTooltip = .ace }
        } else if card.isFaceCard, !ob.seenFaceCardTooltip {
            withAnimation(.spring(response: 0.4)) { activeTooltip = .faceCard }
        } else if card.isJoker, !ob.seenJokerTooltip {
            withAnimation(.spring(response: 0.4)) { activeTooltip = .joker }
        } else if !ob.seenSkipTooltip {
            withAnimation(.spring(response: 0.4)) { activeTooltip = .skip }
        }
    }

    private func dismissTooltip() {
        guard let ob = onboardingState, let tip = activeTooltip else { return }
        switch tip {
        case .ace:      ob.seenAceTooltip      = true
        case .faceCard: ob.seenFaceCardTooltip = true
        case .joker:    ob.seenJokerTooltip    = true
        case .skip:     ob.seenSkipTooltip     = true
        }
        withAnimation(.easeOut(duration: 0.2)) { activeTooltip = nil }
    }

    @ViewBuilder
    private func tooltipOverlay(_ tip: TooltipKind) -> some View {
        VStack {
            Spacer()
            Button(action: dismissTooltip) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DS.Colors.gold)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                            .foregroundStyle(DS.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        Text(tip.body)
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("TAP TO DISMISS")
                            .font(.custom("Oswald-SemiBold", size: 10))
                            .foregroundStyle(DS.Colors.textTertiary)
                            .tracking(1.2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                }
                .padding(18)
                .background(DS.Colors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(DS.Colors.gold.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 130)
            }
            .buttonStyle(.plain)
        }
        .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tooltip kind

private enum TooltipKind {
    case ace, faceCard, joker, skip

    var title: String {
        switch self {
        case .ace:      return "Ace = Hold Exercise"
        case .faceCard: return "Face Cards = 10 Reps"
        case .joker:    return "Joker = Jumping Jacks"
        case .skip:     return "Need to Skip?"
        }
    }

    var body: String {
        switch self {
        case .ace:
            return "Aces trigger a timed hold. Hit START HOLD, hold the position until the timer runs out."
        case .faceCard:
            return "Jacks, Queens, and Kings always count as 10 reps, regardless of difficulty."
        case .joker:
            return "Both Jokers give you Jumping Jacks — the number of reps matches your difficulty setting."
        case .skip:
            return "Tap Skip below to pass on a card. Skipped cards are counted but not in your rep total."
        }
    }
}

// MARK: - Shimmer overlay

private struct ShimmerOverlay: View {
    @State private var offset: CGFloat = -1.0

    var body: some View {
        GeometryReader { geo in
            let bandWidth = geo.size.width * 0.45
            LinearGradient(
                colors: [
                    .white.opacity(0),
                    .white.opacity(0.55),
                    .white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: bandWidth, height: geo.size.height * 1.6)
            .rotationEffect(.degrees(20))
            .offset(x: offset * (geo.size.width + bandWidth))
            .onAppear {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    offset = 1.0
                }
            }
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

// MARK: - Hold timer

private struct HoldTimerView: View {
    let startTime: Date
    let durationSeconds: Int

    @State private var lastAnnounced: Int = -1

    // Threshold shimmer (45 / 30 / 15s) — animates a bright comet around the ring once.
    @State private var shimmerHead: CGFloat = 0
    @State private var shimmerOpacity: Double = 0

    private let ringDiameter: CGFloat = 110
    private let ringLineWidth: CGFloat = 8

    private let announcementThresholds: Set<Int> = [30, 15, 10, 5, 4, 3, 2, 1]
    private let shimmerThresholds: Set<Int> = [45, 30, 15]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = Int(context.date.timeIntervalSince(startTime))
            let remaining = max(0, durationSeconds - elapsed)
            let pct = durationSeconds > 0 ? Double(remaining) / Double(durationSeconds) : 0
            holdRing(remaining: remaining, pct: pct)
                .onChange(of: remaining) { _, secs in
                    announceIfNeeded(secs)
                    if shimmerThresholds.contains(secs) { triggerShimmer() }
                }
        }
    }

    private func triggerShimmer() {
        shimmerHead = 0
        shimmerOpacity = 1
        withAnimation(.easeInOut(duration: 1.0)) {
            shimmerHead = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1000))
            withAnimation(.easeOut(duration: 0.2)) {
                shimmerOpacity = 0
            }
        }
    }

    private func announceIfNeeded(_ remaining: Int) {
        // Hold tick sound + haptic at every second during final 10
        if remaining <= 10 && remaining > 0 {
            SoundPlayer.shared.play(.holdTick, volume: 0.4)
            HapticEngine.shared.play(.holdTick)
        }
        // VoiceOver announcement at key thresholds
        guard UIAccessibility.isVoiceOverRunning,
              announcementThresholds.contains(remaining),
              remaining != lastAnnounced else { return }
        lastAnnounced = remaining
        let msg = remaining == 1 ? "1 second" : "\(remaining) seconds"
        UIAccessibility.post(notification: .announcement, argument: msg)
    }

    /// Smoothly interpolates red → orange → yellow → green over the hold duration.
    private func ringColor(remaining: Int) -> Color {
        let red    = DS.Colors.red
        let orange = Color(hex: "#D4712A")
        let yellow = DS.Colors.gold
        let green  = Color(hex: "#1D6944")

        let total = max(1, Double(durationSeconds))
        let secs  = max(0, min(Double(remaining), total))
        let third = total / 3.0

        if secs >= 2 * third {
            return ColorMath.lerp(orange, red, t: (secs - 2 * third) / third)
        } else if secs >= third {
            return ColorMath.lerp(yellow, orange, t: (secs - third) / third)
        } else {
            return ColorMath.lerp(green, yellow, t: secs / third)
        }
    }

    private func holdRing(remaining: Int, pct: Double) -> some View {
        let color = ringColor(remaining: remaining)
        let m = remaining / 60
        let s = remaining % 60
        let timeStr = "\(m):\(s < 10 ? "0\(s)" : "\(s)")"

        // Shimmer comet: a 0.18-arc-length head that travels around the ring.
        let shimmerTail = max(0, shimmerHead - 0.18)

        return ZStack {
            // Background ring
            Circle()
                .stroke(DS.Colors.bgCard, lineWidth: ringLineWidth)
            // Progress arc
            Circle()
                .trim(from: 0, to: pct)
                .stroke(color, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: pct)
            // Threshold shimmer (45/30/15s) — 1s comet traveling CCW around the ring.
            // scaleEffect(x: -1) mirrors the path so the trim direction reverses.
            Circle()
                .trim(from: shimmerTail, to: shimmerHead)
                .stroke(.white, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1)
                .opacity(shimmerOpacity)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            Text(timeStr)
                .font(.custom("IBMPlexMono-Medium", size: 30))
                .foregroundStyle(color)
        }
        .frame(width: ringDiameter, height: ringDiameter)
    }
}

// MARK: - Animated checkmark ring (hold complete)

private struct AnimatedCheckmarkRing: View {
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color

    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            // Main outline + check, drawn progressively
            CheckmarkRingShape()
                .trim(from: 0, to: progress)
                .stroke(color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            // Bright leading edge — gives the drawing a shimmery feel
            CheckmarkRingShape()
                .trim(from: max(0, progress - 0.06), to: progress)
                .stroke(.white,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .blendMode(.plusLighter)
                .opacity(progress > 0 && progress < 1 ? 1 : 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) { progress = 1 }
        }
    }
}

/// One continuous path: outer ring (12 → CCW around → 1 o'clock),
/// then checkmark inside (1 → 6.5 → 9 o'clock).
private struct CheckmarkRingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * 0.55

        // Clock-position helper. 12 = top, 3 = right, 6 = bottom, 9 = left.
        // Maps to standard math angles where 0° = 3 o'clock and angles grow
        // clockwise in screen space (Y-down).
        func clock(_ hour: Double, radius: CGFloat) -> CGPoint {
            let angle = (hour / 12.0) * 2 * .pi - .pi / 2
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }

        // Start at 12 o'clock, on the outer ring.
        p.move(to: clock(12, radius: outerR))

        // Sweep CCW (visually: leftward from 12) all the way around
        // to 1 o'clock — a 330° arc that "runs around in a circle".
        let segments = 96
        for i in 1...segments {
            let t = Double(i) / Double(segments)
            // -90° start, sweeping by -330° (CCW)
            let angle = -90.0 - t * 330.0
            let rad = angle * .pi / 180.0
            p.addLine(to: CGPoint(
                x: center.x + outerR * cos(rad),
                y: center.y + outerR * sin(rad)
            ))
        }

        // Checkmark: from 1 o'clock outer down to ~6.5 o'clock inner,
        // then up to 9 o'clock inner.
        p.addLine(to: clock(6.5, radius: innerR))
        p.addLine(to: clock(9,   radius: innerR))

        return p
    }
}

// MARK: - Color interpolation helper

private enum ColorMath {
    static func lerp(_ a: Color, _ b: Color, t: Double) -> Color {
        let tt = max(0, min(1, t))
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        UIColor(a).getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        UIColor(b).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            red:   Double(ar) + (Double(br) - Double(ar)) * tt,
            green: Double(ag) + (Double(bg) - Double(ag)) * tt,
            blue:  Double(ab) + (Double(bb) - Double(ab)) * tt
        )
    }
}
