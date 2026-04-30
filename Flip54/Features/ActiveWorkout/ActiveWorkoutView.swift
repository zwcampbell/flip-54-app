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

    // Card flip animation — 3D Y-axis rotation
    @State private var flipDegrees: Double = 0        // 0 = face-down, 180 = face-up
    @State private var flipScale: CGFloat = 1         // subtle mid-flip scale pulse
    @State private var isFlipping = false

    // Card exit animation
    @State private var cardOffsetY: CGFloat = 0
    @State private var cardOpacity: Double = 1

    // Card enter animation
    @State private var showPrescription = false

    // Haptic generators (allocated once)
    private let flipHaptic   = UIImpactFeedbackGenerator(style: .medium)
    private let doneHaptic   = UIImpactFeedbackGenerator(style: .light)
    private let skipHaptic   = UIImpactFeedbackGenerator(style: .light)

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
        let r: CGFloat = 20
        let circ = 2 * Double.pi * r
        let dash = pct * circ

        return HStack(spacing: 12) {
            // Ring + done count
            ZStack {
                Circle()
                    .stroke(DS.Colors.bgRaised, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: done)
                Text("\(done)")
                    .font(.custom("IBMPlexMono-Medium", size: 11))
                    .foregroundStyle(DS.Colors.textPrimary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 0) {
                Text("DONE")
                    .font(.custom("Oswald-SemiBold", size: 10))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .tracking(1.2)
                Text("\(cardsRemaining) left")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            Spacer()

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
            // Card
            Group {
                if let card = currentCard {
                    CardView(card: card, faceUp: isFaceUp,
                             deckId: coordinator.session?.deckId ?? "standard")
                } else {
                    CardView(card: .standard(suit: .hearts, rank: .two), faceUp: false)
                }
            }
            // 3D flip: rotate on Y axis; scaleEffect provides mid-flip size pulse
            .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .scaleEffect(flipScale)
            .offset(y: cardOffsetY)
            .opacity(cardOpacity)
            .onTapGesture {
                if case .cardFaceDown = coordinator.state { handleFlipTap() }
            }

            // Prescription / prompt
            prescriptionArea
                .frame(minHeight: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DS.Layout.horizontalMargin)
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
                    Text("\(count)")
                        .font(.custom("BarlowCondensed-ExtraBold", size: 64))
                        .foregroundStyle(isRed && !isJoker ? DS.Colors.red : DS.Colors.gold)
                    + Text(" reps")
                        .font(.custom("BarlowCondensed-ExtraBold", size: 36))
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
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(DS.Colors.success)
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
            .transition(.scale.combined(with: .opacity))
            Text(completedFully ? "HELD IT!" : "\(secondsHeld)s held")
                .font(.custom("BarlowCondensed-ExtraBold", size: 24))
                .foregroundStyle(DS.Colors.textSecondary)
        }
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
                primaryButton(label: "HOLDING…", enabled: false) { }
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
            Text("Skip")
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
        flipHaptic.prepare()

        // Phase 1: rotate to 90° (card edge-on) — ease-in 0.2s
        withAnimation(.easeIn(duration: 0.20)) {
            flipDegrees = 90
            flipScale = 0.92      // slight shrink at the edge-on moment
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            // Swap face at the hidden moment + fire haptic
            coordinator.send(.flipCard)
            flipHaptic.impactOccurred()

            // Phase 2: continue to 180° — ease-out 0.22s
            withAnimation(.easeOut(duration: 0.22)) {
                flipDegrees = 180
                flipScale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                // Reset degrees invisibly for next flip (card is 180° so reset to 0° = same visual)
                flipDegrees = 0
                withAnimation(.easeOut(duration: 0.2)) { showPrescription = true }
                isFlipping = false
            }
        }
    }

    private func handleDone() {
        doneHaptic.impactOccurred()
        coordinator.send(.markDone(reps: nil, holdSeconds: nil))
        // .cardCompleting is handled in onChange
    }

    private func handleSkip() {
        skipHaptic.impactOccurred()
        coordinator.send(.skip)
        // .cardSkipping is handled in onChange
    }

    private func handleCardAdvance() {
        // Reset animations for next card
        showPrescription = false
        withAnimation(.easeIn(duration: 0.3)) {
            cardOffsetY = -30
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardOffsetY = 0
            cardOpacity = 1
        }
    }

    private func handleStateChange(_ newState: WorkoutState) {
        switch newState {
        case .holdStarting:
            coordinator.send(.startHold)

        case .cardFaceUp(let card, _):
            checkTooltip(for: card)

        case .cardCompleting:
            activeTooltip = nil
            showPrescription = false
            flipDegrees = 0
            flipScale = 1
            withAnimation(.easeIn(duration: 0.35)) {
                cardOffsetY = -40
                cardOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                coordinator.send(.advanceComplete)
                cardOffsetY = 0
                cardOpacity = 1
            }

        case .cardSkipping:
            activeTooltip = nil
            showPrescription = false
            flipDegrees = 0
            flipScale = 1
            withAnimation(.easeIn(duration: 0.28)) {
                cardOffsetY = 40
                cardOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                coordinator.send(.advanceComplete)
                cardOffsetY = 0
                cardOpacity = 1
            }

        case .workoutComplete:
            onWorkoutComplete()

        default:
            break
        }
    }

    // MARK: - Contextual tooltip logic

    private func checkTooltip(for card: Card) {
        guard let ob = onboardingState else { return }
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
                    Image(systemName: tip.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(DS.Colors.gold)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text(tip.body)
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("TAP TO DISMISS")
                            .font(.custom("Oswald-SemiBold", size: 10))
                            .foregroundStyle(DS.Colors.textTertiary)
                            .tracking(1.2)
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
        }
        .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tooltip kind

private enum TooltipKind {
    case ace, faceCard, joker, skip

    var icon: String {
        switch self {
        case .ace:      return "timer"
        case .faceCard: return "star.fill"
        case .joker:    return "bolt.fill"
        case .skip:     return "forward.fill"
        }
    }

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

// MARK: - Hold timer

private struct HoldTimerView: View {
    let startTime: Date
    let durationSeconds: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = Int(context.date.timeIntervalSince(startTime))
            let remaining = max(0, durationSeconds - elapsed)
            let pct = durationSeconds > 0 ? Double(remaining) / Double(durationSeconds) : 0
            holdRing(remaining: remaining, pct: pct)
        }
    }

    private func holdRing(remaining: Int, pct: Double) -> some View {
        let ringColor: Color = pct > 0.75 ? DS.Colors.red
                             : pct > 0.5  ? Color(hex: "#D4712A")
                             : pct > 0.25 ? Color(hex: "#C9A832")
                             :              DS.Colors.success

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(DS.Colors.bgCard, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: pct)

                VStack(spacing: 0) {
                    let secs = remaining % 60
                    let secsStr = secs < 10 ? "0\(secs)" : "\(secs)"
                    Text(":\(secsStr)")
                        .font(.custom("IBMPlexMono-Medium", size: 30))
                        .foregroundStyle(ringColor)
                        .animation(.easeInOut(duration: 0.8), value: remaining)
                    Text("HOLD")
                        .font(.custom("Oswald-SemiBold", size: 10))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .tracking(1.2)
                }
            }
            .frame(width: 112, height: 112)
        }
    }
}
