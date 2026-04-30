import SwiftUI
import Flip54Core
import Flip54Storage

// MARK: - Root container (7 pages + tutorial prompt)

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
        ) {
            WelcomePage()
        }
    }

    private var page1: some View {
        OnboardingPageWrapper(
            page: 1, total: totalPages,
            onSkip: skip,
            cta: "NEXT", onCTA: advance
        ) {
            HowItWorksPage()
        }
    }

    private var page2: some View {
        OnboardingPageWrapper(
            page: 2, total: totalPages,
            onSkip: skip,
            cta: "GOT IT", onCTA: advance
        ) {
            SpecialCardsPage()
        }
    }

    private var page3: some View {
        OnboardingPageWrapper(
            page: 3, total: totalPages,
            onSkip: skip,
            cta: "NEXT", onCTA: advance
        ) {
            SkippingPage()
        }
    }

    private var page4: some View {
        OnboardingPageWrapper(
            page: 4, total: totalPages,
            onSkip: skip,
            cta: "CONTINUE", onCTA: advance
        ) {
            EquipmentPage(settings: settings)
        }
    }

    private var page5: some View {
        OnboardingPageWrapper(
            page: 5, total: totalPages,
            onSkip: skip,
            cta: "CONTINUE", onCTA: advance
        ) {
            DifficultyPage(settings: settings)
        }
    }

    private var page6: some View {
        OnboardingPageWrapper(
            page: 6, total: totalPages,
            onSkip: nil,   // last page — no skip
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
        ) {
            PickDeckPage()
        }
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
                    Button("Skip the tour", action: skip)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textTertiary)
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
                        .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                        .foregroundStyle(Color(hex: "#111111"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(DS.Colors.gold)
                        .clipShape(Capsule())
                }
                if let sec = secondaryCTA, let secAction = onSecondaryCTA {
                    Button(action: secAction) {
                        Text(sec)
                            .font(.custom("Oswald-SemiBold", size: 13))
                            .foregroundStyle(DS.Colors.textTertiary)
                            .tracking(1.2)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }

    private var dotsView: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == page ? DS.Colors.gold : DS.Colors.border)
                    .frame(width: i == page ? 20 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
    }
}

// MARK: - Page 0: Welcome

private struct WelcomePage: View {
    @State private var flipping = false
    @State private var scaleX: CGFloat = 1

    var body: some View {
        VStack(spacing: 28) {
            // Flipping card hero
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(scaleX < 0
                        ? AnyShapeStyle(Color(hex: "#FEFEFE"))
                        : AnyShapeStyle(LinearGradient(colors: [DS.Colors.bgCard, DS.Colors.bgRaised],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .frame(width: 180, height: 252)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.Colors.border, lineWidth: 1.5))
                    .overlay(
                        scaleX < 0
                        ? AnyView(Text("♥").font(.system(size: 80)).foregroundStyle(DS.Colors.red))
                        : AnyView(Text("54").font(.custom("BarlowCondensed-ExtraBold", size: 48)).foregroundStyle(DS.Colors.gold))
                    )
                    .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
                    .scaleEffect(x: scaleX, y: 1)
            }
            .frame(height: 260)
            .onAppear { startFlipLoop() }

            // Headlines
            VStack(spacing: 12) {
                Text("A workout in\nevery shuffle.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 40))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-2)
                Text("Flip a card. Do the reps. Flip again.")
                    .font(.system(size: 17))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
    }

    private func startFlipLoop() {
        Task { @MainActor in
            while true {
                try? await Task.sleep(for: .milliseconds(1800))
                withAnimation(.easeIn(duration: 0.22)) { scaleX = 0.02 }
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.22)) { scaleX = -1 }
                try? await Task.sleep(for: .milliseconds(1800))
                withAnimation(.easeIn(duration: 0.22)) { scaleX = 0.02 }
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.22)) { scaleX = 1 }
            }
        }
    }
}

// MARK: - Page 1: How It Works

private struct HowItWorksPage: View {
    private let suits: [(glyph: String, suit: String, exercise: String, isRed: Bool)] = [
        ("♥", "Hearts",   "Push-ups",   true),
        ("♠", "Spades",   "Pull-ups",   false),
        ("♣", "Clubs",    "Squats",     false),
        ("♦", "Diamonds", "Sit-ups",    true),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Each card is\nan exercise.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 36))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text("The suit chooses what. The number tells you how many.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            // 2×2 card grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(suits, id: \.suit) { s in
                    suitCard(s)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func suitCard(_ s: (glyph: String, suit: String, exercise: String, isRed: Bool)) -> some View {
        let inkColor: Color = s.isRed ? DS.Colors.red : Color(hex: "#111111")
        return VStack(spacing: 4) {
            Text(s.glyph)
                .font(.system(size: 48))
                .foregroundStyle(inkColor)
            Text(s.exercise)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(inkColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(hex: "#FEFEFE"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Page 2: Special Cards

private struct SpecialCardsPage: View {
    private let specials: [(glyph: String, overlay: String, title: String, body: String, color: Color)] = [
        ("♥", "1:00", "Aces",        "1-minute hold. Plank, wall sit, dead hang or push-up hold depending on suit.", DS.Colors.red),
        ("K", "10",   "Face Cards",  "J, Q, K are always 10 reps. A reliable mid-deck beat.", DS.Colors.gold),
        ("★", "40",   "Jokers",      "40 jumping jacks. Always.", DS.Colors.gold),
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Three cards\nbend the rules.")
                .font(.custom("BarlowCondensed-ExtraBold", size: 36))
                .foregroundStyle(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                ForEach(specials, id: \.title) { s in
                    specialCard(s)
                }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(specials, id: \.title) { s in
                    HStack(alignment: .top, spacing: 10) {
                        Text(s.overlay)
                            .font(.custom("IBMPlexMono-Medium", size: 12))
                            .foregroundStyle(s.color)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(DS.Colors.textPrimary)
                            Text(s.body)
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func specialCard(_ s: (glyph: String, overlay: String, title: String, body: String, color: Color)) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#FEFEFE"))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            VStack(spacing: 2) {
                Text(s.glyph)
                    .font(.system(size: 36))
                    .foregroundStyle(s.glyph == "♥" ? DS.Colors.red : Color(hex: "#111111"))
                Text(s.overlay)
                    .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                    .foregroundStyle(s.color)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
    }
}

// MARK: - Page 3: Skipping

private struct SkippingPage: View {
    @State private var animOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Skip if you have to.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 36))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }

            // Skip animation: card arcs from top to bottom of deck
            ZStack {
                // Deck stack
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DS.Colors.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(DS.Colors.border, lineWidth: 1))
                        .frame(width: 80, height: 112)
                        .offset(x: CGFloat(i) * 2, y: CGFloat(i) * -2)
                }
                // Flying card
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(colors: [DS.Colors.bgCard, DS.Colors.bgRaised],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(DS.Colors.border, lineWidth: 1))
                    .frame(width: 80, height: 112)
                    .overlay(Text("?").font(.system(size: 28, weight: .bold)).foregroundStyle(DS.Colors.gold))
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    .offset(x: animOffset, y: animOffset * 0.3)
                    .rotationEffect(.degrees(animOffset * 0.3))
            }
            .frame(height: 160)
            .onAppear { startSkipLoop() }
            .clipped()

            Text("Skipped cards return to the bottom of the deck.\nYou can defer, but you can't escape.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func startSkipLoop() {
        Task { @MainActor in
            while true {
                withAnimation(.easeInOut(duration: 0.6)) { animOffset = 80 }
                try? await Task.sleep(for: .milliseconds(700))
                animOffset = -80
                withAnimation(.easeInOut(duration: 0.6)) { animOffset = 0 }
                try? await Task.sleep(for: .milliseconds(1400))
            }
        }
    }
}

// MARK: - Page 4: Equipment

private struct EquipmentPage: View {
    @Bindable var settings: UserSettings

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("What do\nyou have?")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 36))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                equipRow(icon: "dumbbell.fill",    title: "Dumbbells / Kettlebells", isOn: $settings.hasWeights)
                equipRow(icon: "figure.strengthtraining.traditional", title: "Pull-up Bar", isOn: $settings.hasPullUpBar)
                equipRow(icon: "rectangle.fill",   title: "Yoga Mat", isOn: $settings.hasYogaMat)
            }
            .padding(.horizontal, 24)

            Text("Body-weight only? Skip everything — we've got you.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func equipRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DS.Colors.gold)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DS.Colors.gold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(DS.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.Colors.border, lineWidth: 1))
    }
}

// MARK: - Page 5: Difficulty

private struct DifficultyPage: View {
    @Bindable var settings: UserSettings

    var body: some View {
        VStack(spacing: 20) {
            Text("How hard do\nyou want it?")
                .font(.custom("BarlowCondensed-ExtraBold", size: 36))
                .foregroundStyle(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { level in
                    difficultyRow(level)
                }
            }
            .padding(.horizontal, 24)

            Text("Change this any time in Settings.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textTertiary)
        }
    }

    private func difficultyRow(_ level: Difficulty) -> some View {
        let isSelected = settings.difficulty == level
        return Button {
            settings.difficultyRaw = level.rawValue
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.displayName.uppercased())
                        .font(.custom("BarlowCondensed-ExtraBold", size: 20))
                        .foregroundStyle(isSelected ? DS.Colors.gold : DS.Colors.textPrimary)
                    Text(level.description)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
                Spacer()
                if isSelected {
                    ZStack {
                        Circle().fill(DS.Colors.gold).frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "#111111"))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? DS.Colors.gold : DS.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Page 6: Pick Your Deck

private struct PickDeckPage: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Choose your\nstarter deck.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 36))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text("More unlock as you complete workouts.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textTertiary)
            }

            // Deck carousel — Standard selected, others locked
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Standard deck (unlocked)
                    deckCard(name: "Standard", isUnlocked: true)
                    // Placeholder locked decks
                    ForEach(["Shiny", "Midas", "Digital Camo", "Masonic"], id: \.self) { name in
                        deckCard(name: name, isUnlocked: false)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 230)
        }
    }

    private func deckCard(name: String, isUnlocked: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isUnlocked
                        ? LinearGradient(colors: [DS.Colors.bgCard, DS.Colors.bgRaised], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [DS.Colors.bgRaised, DS.Colors.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 168)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isUnlocked ? DS.Colors.gold : DS.Colors.border, lineWidth: isUnlocked ? 2 : 1))
                Text("54")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                    .foregroundStyle(isUnlocked ? DS.Colors.gold : DS.Colors.textTertiary)
                if !isUnlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(DS.Colors.textTertiary)
                                .padding(8)
                        }
                    }
                    .frame(width: 120, height: 168)
                }
                if isUnlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(DS.Colors.gold)
                                .padding(8)
                        }
                    }
                    .frame(width: 120, height: 168)
                }
            }
            Text(name)
                .font(.system(size: 12, weight: isUnlocked ? .semibold : .regular))
                .foregroundStyle(isUnlocked ? DS.Colors.textPrimary : DS.Colors.textTertiary)
        }
    }
}

// Reuse AnyView wrapper for type erasure
private struct AnyViewWrapper<Content: View>: View {
    let content: Content
    init(_ content: Content) { self.content = content }
    var body: some View { content }
}
