import SwiftUI
import Flip54DesignSystem

@main
struct Flip54WatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}

/// Placeholder root until step 3: a vertical gallery of the step 2 components
/// so they can be checked on a simulator. Replaced by the Start screen in step 3.
struct WatchRootView: View {
    /// `-galleryPage N` at launch opens page N, for simulator screenshots.
    @State private var page = UserDefaults.standard.integer(forKey: "galleryPage")

    var body: some View {
        TabView(selection: $page) {
            gallery(0, WatchDeckFan().frame(height: 90))
            gallery(1, WatchCardBack())
            gallery(2, PrescriptionView(card: .standard(suit: .hearts, rank: .seven),
                                     prescription: .reps(exercise: .jumpingSquat, count: 7)))
            gallery(3, PrescriptionView(card: .standard(suit: .spades, rank: .king),
                                     prescription: .reps(exercise: .hinduPushUp, count: 10)))
            gallery(4, PrescriptionView(card: .standard(suit: .diamonds, rank: .ace),
                                     prescription: .hold(exercise: .hollowBodyHold, seconds: 60)))
            gallery(5, PrescriptionView(card: .joker(variant: .black),
                                     prescription: .reps(exercise: .jumpingJacks, count: 40)))
            gallery(6, HoldTimerRing(remaining: 45, total: 60))
            gallery(7, HoldCompleteBadge())
            gallery(8, Grid(horizontalSpacing: 6, verticalSpacing: 8) {
                GridRow {
                    ControlTile(title: "End", systemImage: "xmark", tone: .destructive) {}
                    ControlTile(title: "Pause", systemImage: "pause.fill", tone: .gold) {}
                }
                GridRow {
                    ControlTile(title: "Skip", systemImage: "forward.end.fill") {}
                    ControlTile(title: "Guide", systemImage: "questionmark.circle") {}
                }
            })
            gallery(9, VStack(spacing: 12) {
                DeckProgressTicks(flipped: 12, total: 54)
                HStack {
                    SummaryStat(value: "412", label: "Reps")
                    SummaryStat(value: "54", label: "Cards")
                    SummaryStat(value: "27:40", label: "Time")
                }
                WatchInfoRow("Deck", value: "Standard · Full")
            })
            gallery(10, VStack(spacing: 4) {
                SetupRow(label: "Difficulty", value: "Standard", detail: "1.0×") {}
                WatchOptionRow(title: "Standard", subtitle: "As prescribed.", trailing: "1.0×", isSelected: true) {}
                WatchOptionRow(title: "Advanced", subtitle: "Push it.", trailing: "2.0×", isSelected: false) {}
            })
        }
        .tabViewStyle(.verticalPage)
        // The watch background is pure black, not DS.Colors.bg, so the OLED stays dark.
        .background(Color.black)
    }

    private func gallery(_ tag: Int, _ content: some View) -> some View {
        VStack(spacing: 6) {
            HStack {
                CardsLeftHeader(remaining: 42, total: 54)
                Spacer()
            }
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
            WatchActionButton(title: "Done") {}
        }
        .padding(.horizontal, WatchLayout.edge)
        .background(Color.black)
        .tag(tag)
    }
}

#Preview {
    WatchRootView()
}
