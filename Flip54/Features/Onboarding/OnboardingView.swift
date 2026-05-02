import SwiftUI
import Flip54Core
import Flip54Storage

// MARK: - Root container (7 pages)

struct OnboardingView: View {
    @Bindable var state: OnboardingState
    @Bindable var settings: UserSettings
    let onComplete: (Bool) -> Void   // Bool = startTutorial

    @State private var page = 0
    private let totalPages = 7

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            TabView(selection: $page) {
                page0.tag(0)
                page1.tag(1)
                page2.tag(2)
                page3.tag(3)
                page4.tag(4)
                page5.tag(5)
                page6.tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: page)
        }
    }

    // MARK: - Skip / advance helpers

    private func skip() {
        state.hasSeenWelcome = true
        state.hasSetEquipmentAndDifficulty = true
        onComplete(false)
    }

    private func advance() {
        withAnimation { page = min(page + 1, totalPages - 1) }
    }

    // MARK: - Page views

    private var page0: some View {
        OnboardingPageWrapper(
            page: 0, total: totalPages,
            onSkip: skip,
            cta: "GET STARTED", onCTA: advance
        ) { WelcomePage() }
    }

    private var page1: some View {
        OnboardingPageWrapper(
            page: 1, total: totalPages,
            onSkip: skip,
            cta: "NEXT", onCTA: advance
        ) { HowItWorksPage() }
    }

    private var page2: some View {
        OnboardingPageWrapper(
            page: 2, total: totalPages,
            onSkip: skip,
            cta: "GOT IT", onCTA: advance
        ) { SpecialCardsPage() }
    }

    private var page3: some View {
        OnboardingPageWrapper(
            page: 3, total: totalPages,
            onSkip: skip,
            cta: "NEXT", onCTA: advance
        ) { SkippingPage() }
    }

    private var page4: some View {
        OnboardingPageWrapper(
            page: 4, total: totalPages,
            onSkip: skip,
            cta: "CONTINUE", onCTA: advance
        ) { EquipmentPage(settings: settings) }
    }

    private var page5: some View {
        OnboardingPageWrapper(
            page: 5, total: totalPages,
            onSkip: skip,
            cta: "CONTINUE", onCTA: advance
        ) { DifficultyPage(settings: settings) }
    }

    private var page6: some View {
        OnboardingPageWrapper(
            page: 6, total: totalPages,
            onSkip: nil,
            cta: "START FIRST WORKOUT",
            onCTA: {
                state.hasSeenWelcome = true
                state.hasSetEquipmentAndDifficulty = true
                onComplete(false)
            },
            secondaryCTA: "TRY THE 5-CARD TUTORIAL",
            onSecondaryCTA: {
                state.hasSeenWelcome = true
                state.hasSetEquipmentAndDifficulty = true
                onComplete(true)
            }
        ) { PickDeckPage() }
    }
}

// MARK: - Sized card helper

/// Renders `CardPlaceholderView` at a custom width while preserving aspect ratio.
struct SizedCardView: View {
    let card: Card
    let faceUp: Bool
    let width: CGFloat

    private var scale: CGFloat { width / CardPlaceholderView.cardWidth }
    private var height: CGFloat { CardPlaceholderView.cardHeight * scale }

    var body: some View {
        CardPlaceholderView(card: card, faceUp: faceUp)
            .scaleEffect(scale)
            .frame(width: width, height: height)
    }
}

// MARK: - Page wrapper (skip bar + dots + CTA)

private struct OnboardingPageWrapper<Content: View>: View {
    let page: Int
    let total: Int
    let onSkip: (() -> Void)?
    let cta: String
    let onCTA: () -> Void
    var secondaryCTA: String? = nil
    var onSecondaryCTA: (() -> Void)? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            // Top bar — Skip link
            HStack {
                Spacer()
                if let skip = onSkip {
                    Button(action: skip) {
                        Text("SKIP")
                            .font(.custom("Oswald-SemiBold", size: 12))
                            .foregroundStyle(DS.Colors.textTertiary)
                            .tracking(1.4)
                    }
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 24)

            // Main content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Dots + CTA
            VStack(spacing: 14) {
                dotsView
                Button(action: onCTA) {
                    Text(cta)
                        .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                        .foregroundStyle(Color(hex: "#111111"))
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(DS.Colors.gold)
                        .clipShape(Capsule())
                        .shadow(color: DS.Colors.gold.opacity(0.25), radius: 12)
                }
                if let sec = secondaryCTA, let secAction = onSecondaryCTA {
                    Button(action: secAction) {
                        Text(sec)
                            .font(.custom("Oswald-SemiBold", size: 13))
                            .foregroundStyle(DS.Colors.textTertiary)
                            .tracking(1.4)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private var dotsView: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == page ? DS.Colors.gold : DS.Colors.border)
                    .frame(width: i == page ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
    }
}

// MARK: - Page 0: Welcome

private struct WelcomePage: View {
    @State private var wobble: Double = 0

    private struct FanCard {
        let card: Card
        let faceUp: Bool
        let rot: Double
        let dx: CGFloat
        let dy: CGFloat
    }

    private var cards: [FanCard] {
        [
            FanCard(card: .standard(suit: .hearts,   rank: .seven), faceUp: false, rot: -14, dx: -50, dy: 20),
            FanCard(card: .standard(suit: .diamonds, rank: .ace),   faceUp: true,  rot:   0, dx:   0, dy:  0),
            FanCard(card: .standard(suit: .spades,   rank: .king),  faceUp: false, rot:  14, dx:  50, dy: 20),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Fanned card hero
            ZStack {
                ForEach(cards.indices, id: \.self) { i in
                    let c = cards[i]
                    SizedCardView(card: c.card, faceUp: c.faceUp, width: 150)
                        .rotationEffect(.degrees(c.rot + (i == 1 ? sin(wobble) * 3 : 0)))
                        .offset(x: c.dx, y: c.dy)
                        .zIndex(Double(3 - i))
                }
            }
            .frame(height: 260)
            .onAppear { startWobble() }

            Spacer()

            // Headlines
            VStack(spacing: 12) {
                Text("A WORKOUT IN\nEVERY SHUFFLE.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 42))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .lineSpacing(-4)
                Text("Flip a card. Do the reps. Flip again.")
                    .font(.system(size: 17))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private func startWobble() {
        Task { @MainActor in
            while true {
                try? await Task.sleep(for: .milliseconds(16))
                wobble += 0.014   // ~0.8 deg per tick like prototype
                if wobble > .pi * 2 { wobble -= .pi * 2 }
            }
        }
    }
}

// MARK: - Page 1: How It Works

private struct HowItWorksPage: View {
    private struct Slot {
        let card: Card
        let label: String
        let isRed: Bool
    }

    private let slots: [Slot] = [
        Slot(card: .standard(suit: .hearts,   rank: .seven), label: "PUSH-UPS",   isRed: true),
        Slot(card: .standard(suit: .spades,   rank: .jack),  label: "PULL-UPS",   isRed: false),
        Slot(card: .standard(suit: .clubs,    rank: .four),  label: "TOTAL BODY", isRed: false),
        Slot(card: .standard(suit: .diamonds, rank: .nine),  label: "CORE",       isRed: true),
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 20)
            VStack(spacing: 10) {
                Text("EACH CARD IS\nAN EXERCISE.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 38))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .lineSpacing(-4)
                Text("The suit chooses what. The number tells you how many.")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(slots.indices, id: \.self) { i in
                    slotCell(slots[i])
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func slotCell(_ s: Slot) -> some View {
        VStack(spacing: 10) {
            SizedCardView(card: s.card, faceUp: true, width: 78)
            Text(s.label)
                .font(.custom("Oswald-SemiBold", size: 13))
                .foregroundStyle(s.isRed ? DS.Colors.red : DS.Colors.textPrimary)
                .tracking(1.0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(DS.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(DS.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Page 2: Special Cards

private struct SpecialCardsPage: View {
    private struct Row {
        let label: String
        let color: Color
        let body: String
    }

    private let cards: [(card: Card, faceUp: Bool)] = [
        (.standard(suit: .hearts, rank: .ace),  true),
        (.standard(suit: .spades, rank: .king), true),
        (.joker(variant: .black),               true),
    ]

    private let rows: [Row] = [
        Row(label: "Aces",       color: DS.Colors.red,            body: "1-minute hold. Suit-specific form."),
        Row(label: "Face Cards", color: DS.Colors.textSecondary,  body: "10 reps each, every time."),
        Row(label: "Jokers",     color: DS.Colors.gold,           body: "40 jumping jacks. Always."),
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)
            Text("THREE CARDS\nBEND THE RULES.")
                .font(.custom("BarlowCondensed-ExtraBold", size: 38))
                .foregroundStyle(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(0.5)
                .lineSpacing(-4)

            HStack(spacing: 14) {
                ForEach(cards.indices, id: \.self) { i in
                    SizedCardView(card: cards[i].card, faceUp: cards[i].faceUp, width: 92)
                }
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(rows.indices, id: \.self) { i in
                    let r = rows[i]
                    HStack(spacing: 12) {
                        Text(r.label)
                            .font(.custom("Oswald-SemiBold", size: 13))
                            .foregroundStyle(r.color)
                            .tracking(0.4)
                            .frame(width: 96, alignment: .leading)
                        Text(r.body)
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(DS.Colors.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(DS.Colors.border, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Page 3: Skipping

private struct SkippingPage: View {
    @State private var animOffset: CGFloat = 0
    @State private var animRotation: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 30)

            ZStack {
                // Deck stack (face-down)
                ForEach(0..<3, id: \.self) { i in
                    SizedCardView(card: .standard(suit: .hearts, rank: .seven),
                                  faceUp: false,
                                  width: 110)
                        .offset(x: -30 + CGFloat(i) * 4, y: CGFloat(i) * 4)
                        .opacity(0.5 + Double(i) * 0.25)
                        .zIndex(Double(i))
                }
                // Flying skipped card
                SizedCardView(card: .standard(suit: .clubs, rank: .nine),
                              faceUp: true,
                              width: 90)
                    .rotationEffect(.degrees(animRotation))
                    .offset(x: 60 + animOffset, y: animOffset * 0.3)
                    .zIndex(10)
            }
            .frame(height: 200)
            .onAppear { startSkipLoop() }
            .clipped()

            VStack(spacing: 12) {
                Text("SKIP IF\nYOU HAVE TO.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 38))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                    .lineSpacing(-4)

                Text("Skipped cards return to the bottom of the deck. You can defer, but you can't escape.")
                    .font(.system(size: 16))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private func startSkipLoop() {
        Task { @MainActor in
            while true {
                animOffset = 0
                animRotation = -10
                withAnimation(.easeInOut(duration: 0.7)) {
                    animOffset = 90
                    animRotation = 6
                }
                try? await Task.sleep(for: .milliseconds(900))
                animOffset = -90
                animRotation = -10
                withAnimation(.easeInOut(duration: 0.6)) {
                    animOffset = 0
                }
                try? await Task.sleep(for: .milliseconds(1300))
            }
        }
    }
}

// MARK: - Page 4: Equipment

private struct EquipmentPage: View {
    @Bindable var settings: UserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT DO\nYOU HAVE?")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 42))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(0.5)
                    .lineSpacing(-4)
                Text("Body-weight only? No problem — we've got you.")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            VStack(spacing: 10) {
                row(icon: "🏋️", label: "Weights",     sub: "Dumbbells or kettlebells",
                    isOn: settings.hasWeights)    {
                        HapticEngine.shared.play(.tap)
                        settings.hasWeights.toggle()
                    }
                row(icon: "🪀", label: "Pull-up Bar", sub: "Fixed or doorframe bar",
                    isOn: settings.hasPullUpBar)  {
                        HapticEngine.shared.play(.tap)
                        settings.hasPullUpBar.toggle()
                    }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func row(icon: String, label: String, sub: String, isOn: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.custom("Oswald-SemiBold", size: 15))
                        .foregroundStyle(isOn ? DS.Colors.gold : DS.Colors.textPrimary)
                    Text(sub)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isOn ? DS.Colors.gold : DS.Colors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isOn {
                        Circle()
                            .fill(DS.Colors.gold)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "#111111"))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isOn ? DS.Colors.goldSoft : DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isOn ? DS.Colors.gold : DS.Colors.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page 5: Difficulty

private struct DifficultyPage: View {
    @Bindable var settings: UserSettings

    private struct Opt {
        let level: Difficulty
        let label: String
        let mult: String
        let sub: String
        let color: Color
    }

    private var opts: [Opt] {
        [
            Opt(level: .beginner, label: "BEGINNER", mult: "0.75×", sub: "Build the habit.", color: DS.Colors.success),
            Opt(level: .standard, label: "STANDARD", mult: "1.00×", sub: "As prescribed.",   color: DS.Colors.gold),
            Opt(level: .advanced, label: "ADVANCED", mult: "1.25×", sub: "Push it.",         color: DS.Colors.red),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("HOW HARD?")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 42))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(0.5)
                Text("Change this any time in Settings.")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            VStack(spacing: 10) {
                ForEach(opts.indices, id: \.self) { i in
                    let o = opts[i]
                    let selected = settings.difficulty == o.level
                    Button {
                        settings.difficultyRaw = o.level.rawValue
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(o.label)
                                    .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                                    .foregroundStyle(selected ? o.color : DS.Colors.textPrimary)
                                    .tracking(1.0)
                                Text(o.sub)
                                    .font(.system(size: 13))
                                    .foregroundStyle(DS.Colors.textTertiary)
                            }
                            Spacer()
                            Text(o.mult)
                                .font(.custom("IBMPlexMono-Medium", size: 20))
                                .foregroundStyle(selected ? o.color : DS.Colors.textTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(selected ? DS.Colors.goldSoft : DS.Colors.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(selected ? o.color : DS.Colors.border, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Page 6: Pick Your Deck

private struct PickDeckPage: View {
    private struct Deck {
        let name: String
        let bg: Color
        let accent: Color
        let unlocked: Bool
        let lockText: String?
    }

    private let decks: [Deck] = [
        Deck(name: "Standard",    bg: Color(hex: "#1A1A22"), accent: Color(hex: "#9D9DAA"), unlocked: true,  lockText: nil),
        Deck(name: "Holographic", bg: Color(hex: "#180E28"), accent: Color(hex: "#8B5CF6"), unlocked: false, lockText: "3 workouts"),
        Deck(name: "Midas",       bg: Color(hex: "#1A1508"), accent: DS.Colors.gold,        unlocked: false, lockText: "10 workouts"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)
            VStack(alignment: .leading, spacing: 8) {
                Text("CHOOSE YOUR\nSTARTER DECK.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 38))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(0.5)
                    .lineSpacing(-4)
                Text("More unlock as you complete workouts.")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            HStack(spacing: 12) {
                ForEach(decks.indices, id: \.self) { i in
                    deckThumbnail(decks[i])
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func deckThumbnail(_ d: Deck) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(d.bg)
                    .frame(width: 100, height: 140)

                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(d.unlocked ? d.accent : DS.Colors.border, lineWidth: d.unlocked ? 2 : 1)
                    .frame(width: 100, height: 140)

                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(d.accent.opacity(0.2), lineWidth: 1)
                    .padding(6)
                    .frame(width: 100, height: 140)

                Text("54")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 16))
                    .foregroundStyle(d.accent.opacity(0.6))

                if !d.unlocked {
                    Text("🔒")
                        .font(.system(size: 13))
                        .frame(maxWidth: 100, maxHeight: 140, alignment: .topTrailing)
                        .padding(8)
                }
            }
            .frame(width: 100, height: 140)

            Text(d.name)
                .font(.custom("Oswald-SemiBold", size: 11))
                .foregroundStyle(d.unlocked ? DS.Colors.gold : DS.Colors.textSecondary)
                .tracking(1.2)

            if let lock = d.lockText {
                Text(lock)
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Colors.textTertiary)
            } else {
                Text(" ")
                    .font(.system(size: 10))
            }
        }
        .frame(width: 100)
    }
}
