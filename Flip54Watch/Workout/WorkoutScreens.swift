import SwiftUI
import WatchKit
import Flip54Core
import Flip54DesignSystem
import Flip54Storage
import Flip54WorkoutEngine

/// The running workout: Controls ← Card → Now Playing, swiped sideways.
struct WorkoutScreen: View {
    @Environment(WatchWorkoutModel.self) private var model
    @State private var page = Page.card
    @State private var showProgress = false

    enum Page: Hashable { case controls, card, nowPlaying }

    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                ControlsPage(onAction: { page = .card })
                    .tag(Page.controls)
                CardPage()
                    .tag(Page.card)
                NowPlayingView()
                    .tag(Page.nowPlaying)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let session = model.session {
                        Button { showProgress = true } label: {
                            CardsLeftHeader(remaining: session.cardsRemaining, total: session.deckSize)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Shows workout progress")
                    }
                }
            }
            .overlay(alignment: .top) {
                WatchPageDots(count: 3, selected: [Page.controls, .card, .nowPlaying].firstIndex(of: page) ?? 1)
                    .padding(.top, 2)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showProgress) { ProgressSheet() }
        }
    }
}

// MARK: - Card page

struct CardPage: View {
    @Environment(WatchWorkoutModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Horizontal scale of the card during a flip: the back narrows to its
    /// edge (1 → 0), swaps to the face, and the face widens back (0 → 1).
    /// A squash rather than a 3D turn, since watchOS doesn't draw views
    /// mid-way through a perspective rotation.
    @State private var flipSquash: CGFloat = 1
    @State private var isFlipping = false
    /// False while the freshly flipped card is still centred and turning.
    @State private var showsTarget = true

    /// Face-down card is drawn larger than the face-up one; it shrinks to the
    /// face's size while turning so the swap at edge-on doesn't jump.
    private static let backToFaceScale = 66.0 / 75.0

    /// After a flip, taps are ignored this long so a quick double tap can't
    /// flip a card and mark it done before it's been read.
    private static let postFlipLock: Duration = .milliseconds(350)

    /// The whole page is the control: tap to flip, tap again when done. It's a
    /// real (plain) button so Double Tap and VoiceOver still reach it.
    var body: some View {
        Button(action: primaryAction) {
            VStack(spacing: 6) {
                Spacer(minLength: 0)
                content
                Spacer(minLength: 0)
                tapHint
            }
            .padding(.horizontal, WatchLayout.edge)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .handGestureShortcut(.primaryAction)
        .accessibilityHint(hintText ?? "")
        .animation(.easeOut(duration: 0.22), value: model.state)
        .ignoresSafeArea(edges: .bottom)
        .background(Color.black)
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .shuffling:
            VStack(spacing: 8) {
                WatchDeckFan().frame(height: 80)
                Text("SHUFFLING")
                    .font(WatchType.sub(11)).tracking(1)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .transition(.opacity)
        case .cardFaceDown:
            VStack(spacing: 8) {
                WatchCardBack()
                    .scaleEffect(flipSquash < 1 ? Self.backToFaceScale : 1)
                    .scaleEffect(x: flipSquash, y: 1)
                if let session = model.session {
                    Text("CARD \(session.cardsCompleted + 1) OF \(session.deckSize)")
                        .font(WatchType.sub(11)).tracking(1)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .opacity(flipSquash < 1 ? 0 : 1)
                }
            }
            // The next card deals in; the flip swap below runs without animation.
            .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .identity))
        case .cardFaceUp(let card, let prescription):
            PrescriptionView(card: card, prescription: prescription, showsTarget: showsTarget,
                             cardSquash: flipSquash)
                .transition(.identity)
        case .cardCompleting(let card):
            leaving(card, completed: true).modifier(FlyOff(toRight: true)).transition(.identity)
        case .cardSkipping(let card):
            leaving(card, completed: false).modifier(FlyOff(toRight: false)).transition(.identity)
        case .holdStarting(let card):
            PrescriptionView(card: card, prescription: currentPrescription(card))
        case .holding(let card, let start, let duration):
            HoldingView(card: card, start: start, duration: duration)
                .transition(.opacity)
        case .holdComplete(let card, let held, _):
            holdComplete(card: card, held: held)
                .transition(.opacity)
        default:
            EmptyView()
        }
    }

    /// What slides off when a card is finished or skipped: whatever was showing for it.
    /// A completed Ace was last showing Hold complete.
    @ViewBuilder private func leaving(_ card: Card, completed: Bool) -> some View {
        if card.isAce && completed {
            holdComplete(card: card, held: 0, showsDetail: false)
        } else {
            PrescriptionView(card: card, prescription: currentPrescription(card))
        }
    }

    private func holdComplete(card: Card, held: Int, showsDetail: Bool = true) -> some View {
        VStack(spacing: 8) {
            HoldCompleteBadge(diameter: 86)
            VStack(spacing: 3) {
                Text("HOLD COMPLETE")
                    .font(WatchType.sub(15)).tracking(0.75)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("\(watchClock(held)) · \(holdName(for: card))")
                    .font(WatchType.body(11))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .opacity(showsDetail ? 1 : 0)
            }
        }
    }

    // MARK: Flip

    private func flip() {
        guard !isFlipping, case .cardFaceDown = model.state else { return }
        isFlipping = true
        if reduceMotion {
            model.flip()
            Task { @MainActor in
                try? await Task.sleep(for: Self.postFlipLock)
                isFlipping = false
            }
            return
        }
        showsTarget = false
        Task { @MainActor in
            // Started from the task rather than the button action: on watchOS an
            // animation begun inside this button's action is dropped.
            withAnimation(.easeIn(duration: 0.16)) { flipSquash = 0.02 }
            try? await Task.sleep(for: .milliseconds(160))
            // Edge-on: swap the back for the face without animating the swap.
            var swap = Transaction()
            swap.disablesAnimations = true
            withTransaction(swap) { model.flip() }
            // Let the face render once at edge-on so it has a width to grow from.
            try? await Task.sleep(for: .milliseconds(20))
            withAnimation(.easeOut(duration: 0.2)) { flipSquash = 1 }
            try? await Task.sleep(for: .milliseconds(260))
            // Glide the card left; the reps fade in behind it.
            withAnimation(.spring(duration: 0.35, bounce: 0.12)) { showsTarget = true }
            try? await Task.sleep(for: Self.postFlipLock)
            isFlipping = false
        }
    }

    // MARK: Tap

    private func primaryAction() {
        guard !isFlipping else { return }
        switch model.state {
        case .cardFaceDown:
            flip()
        case .cardFaceUp, .holdComplete:
            model.done()
        default:
            break  // Shuffling, holding or a card leaving: nothing to do yet.
        }
    }

    /// What a tap will do right now, or nil when it does nothing.
    private var hintText: String? {
        switch model.state {
        case .cardFaceDown: "Tap to flip"
        case .cardFaceUp(_, let prescription): prescription.isHold ? "Tap to start hold" : "Tap when done"
        case .holdComplete: "Tap to continue"
        default: nil
        }
    }

    /// Small prompt where the action button used to be. Kept at a fixed height
    /// so the card doesn't shift as the prompt comes and goes.
    private var tapHint: some View {
        HStack(spacing: 4) {
            if let hintText {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 11))
                Text(hintText.uppercased())
                    .font(WatchType.sub(11))
                    .tracking(1)
            }
        }
        .foregroundStyle(DS.Colors.gold)
        .opacity(isFlipping ? 0 : 1)
        .frame(height: 22)
        .padding(.bottom, 10)
        .accessibilityHidden(true)
    }

    private func currentPrescription(_ card: Card) -> Prescription {
        let session = model.session
        return prescription(for: card, equipment: session?.equipment ?? .bodyWeightOnly,
                            difficulty: session?.difficulty ?? .standard)
    }

    private func holdName(for card: Card) -> String {
        currentPrescription(card).exercise.displayName
    }
}

/// Sends a finished card off the side of the screen: right for Done, left for Skip.
/// Runs a little under the model's 300 ms advance delay.
private struct FlyOff: ViewModifier {
    let toRight: Bool
    @State private var gone = false

    func body(content: Content) -> some View {
        content
            .offset(x: gone ? (toRight ? 230 : -230) : 0, y: gone ? 14 : 0)
            .rotationEffect(.degrees(gone ? (toRight ? 14 : -14) : 0))
            .opacity(gone ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 0.26)) { gone = true }
            }
    }
}

/// Ace hold in progress: countdown ring, exercise name, "Hold steady".
private struct HoldingView: View {
    @Environment(WatchWorkoutModel.self) private var model
    let card: Card
    let start: Date
    let duration: Int

    var body: some View {
        TimelineView(.periodic(from: start, by: 1)) { context in
            let remaining = max(0, duration - Int(context.date.timeIntervalSince(start)))
            VStack(spacing: 6) {
                HoldTimerRing(remaining: remaining, total: duration, diameter: 118)
                VStack(spacing: 2) {
                    Text(exerciseName.uppercased())
                        .font(WatchType.sub(13)).tracking(0.5)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("HOLD STEADY")
                        .font(WatchType.sub(10)).tracking(1)
                        .foregroundStyle(DS.Colors.gold)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
    }

    private var exerciseName: String {
        guard let session = model.session else { return "" }
        return prescription(for: card, equipment: session.equipment, difficulty: session.difficulty)
            .exercise.displayName
    }
}

// MARK: - Controls page

struct ControlsPage: View {
    @Environment(WatchWorkoutModel.self) private var model
    /// Called after an action that should bring the card page back.
    let onAction: () -> Void
    @State private var confirmEnd = false
    @State private var showGuide = false

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 8) {
            GridRow {
                ControlTile(title: "End", systemImage: "xmark", tone: .destructive) { confirmEnd = true }
                ControlTile(title: "Pause", systemImage: "pause.fill", tone: .gold) { model.pause() }
            }
            GridRow {
                ControlTile(title: "Skip", systemImage: "forward.end.fill") {
                    model.skip()
                    onAction()
                }
                .disabled(!canSkip)
                .opacity(canSkip ? 1 : 0.4)
                ControlTile(title: "Guide", systemImage: "questionmark.circle") { showGuide = true }
                    .disabled(currentExercise == nil)
                    .opacity(currentExercise == nil ? 0.4 : 1)
            }
        }
        .padding(.horizontal, WatchLayout.edge)
        .background(Color.black)
        .confirmationDialog("End workout?", isPresented: $confirmEnd) {
            Button("End workout", role: .destructive) { model.end() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text(endMessage)
        }
        .sheet(isPresented: $showGuide) {
            if let currentExercise { GuideSheet(exercise: currentExercise) }
        }
    }

    private var canSkip: Bool {
        switch model.state {
        case .cardFaceUp, .holding: true
        default: false
        }
    }

    private var currentExercise: Exercise? {
        switch model.state {
        case .cardFaceUp(_, let prescription): return prescription.exercise
        case .holding(let card, _, _), .holdComplete(let card, _, _):
            guard let session = model.session else { return nil }
            return prescription(for: card, equipment: session.equipment, difficulty: session.difficulty).exercise
        default: return nil
        }
    }

    private var endMessage: String {
        let done = model.session?.cardsCompleted ?? 0
        return done > 0
            ? "You've done \(done) \(done == 1 ? "card" : "cards"). You'll see a summary."
            : "Nothing's been done yet."
    }
}

// MARK: - Sheets

/// Swipe-up page in the design; opened by tapping the cards-left header.
struct ProgressSheet: View {
    @Environment(WatchWorkoutModel.self) private var model

    var body: some View {
        if let session = model.session {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(session.totalRepsCompleted)")
                            .font(WatchType.display(64))
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text("REPS")
                            .font(WatchType.sub(13)).tracking(1.5)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    DeckProgressTicks(flipped: session.cardsCompleted, total: session.deckSize)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        HStack(alignment: .firstTextBaseline) {
                            stat("\(session.cardsCompleted)", "OF \(session.deckSize)")
                            Spacer()
                            stat(watchClock(Int(WatchWorkoutModel.activeDuration(of: session, at: context.date))), "TIME")
                        }
                    }
                    WatchInfoRow("Deck", value: "\(session.difficulty.displayName) · \(session.deckSize < 54 ? "Half" : "Full")")
                }
                .padding(.horizontal, WatchLayout.edge)
            }
            .background(Color.black)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value).font(WatchType.mono(17)).foregroundStyle(DS.Colors.textPrimary)
            Text(label).font(WatchType.sub(10)).tracking(1).foregroundStyle(DS.Colors.textSecondary)
        }
    }
}

/// Form cues for the current exercise, from the shared form-guide copy.
struct GuideSheet: View {
    let exercise: Exercise

    var body: some View {
        let guide = FormGuideData.guide(for: exercise)
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.displayName.uppercased())
                    .font(WatchType.sub(15)).tracking(0.5)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(guide.tempoLabel)
                    .font(WatchType.mono(11))
                    .foregroundStyle(DS.Colors.gold)
                ForEach(guide.cues, id: \.self) { cue in
                    Label(cue, systemImage: "checkmark")
                        .font(WatchType.body(11))
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                if !guide.watch.isEmpty {
                    Text("WATCH FOR")
                        .font(WatchType.sub(10)).tracking(1)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .padding(.top, 4)
                    ForEach(guide.watch, id: \.self) { item in
                        Label(item, systemImage: "exclamationmark.triangle")
                            .font(WatchType.body(11))
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
    }
}
