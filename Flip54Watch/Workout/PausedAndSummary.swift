import SwiftUI
import Flip54Core
import Flip54DesignSystem

struct PausedScreen: View {
    @Environment(WatchWorkoutModel.self) private var model
    @State private var confirmEnd = false

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            if let session = model.session {
                Text(watchClock(Int(WatchWorkoutModel.activeDuration(of: session, at: .now))))
                    .font(WatchType.mono(46))
                    .tracking(-1)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("\(session.cardsCompleted) OF \(session.deckSize) FLIPPED")
                    .font(WatchType.sub(11)).tracking(1)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                WatchActionButton(title: "End", kind: .destructive) { confirmEnd = true }
                WatchActionButton(title: "Resume", systemImage: "play.fill") { model.resume() }
                    .handGestureShortcut(.primaryAction)
            }
        }
        .padding(.horizontal, WatchLayout.edge)
        .ignoresSafeArea(edges: .bottom)
        .background(Color.black)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Label("PAUSED", systemImage: "pause.fill")
                    .labelStyle(.titleAndIcon)
                    .font(WatchType.sub(14)).tracking(0.75)
                    .foregroundStyle(DS.Colors.gold)
            }
        }
        .confirmationDialog("End workout?", isPresented: $confirmEnd) {
            Button("End workout", role: .destructive) { model.end() }
            Button("Keep going", role: .cancel) {}
        }
    }
}

/// End of a workout: "Deck cleared." (or "Workout ended." when stopped early),
/// headline stats, then detail rows below the fold.
struct SummaryScreen: View {
    @Environment(WatchWorkoutModel.self) private var model
    let summary: WatchWorkoutSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(summary.endedEarly ? "Workout\nended." : "Deck\ncleared.")
                    .font(WatchType.display(30))
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-4)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .padding(.top, 4)
                HStack(spacing: 4) {
                    SummaryStat(value: "\(summary.reps)", label: "Reps")
                    SummaryStat(value: "\(summary.cardsCompleted)", label: "Cards")
                    SummaryStat(value: watchClock(Int(summary.duration)), label: "Time")
                }
                VStack(spacing: 3) {
                    WatchInfoRow(label: "Avg per card") {
                        Text(watchClock(Int(summary.averagePerCard))).font(WatchType.mono(12))
                    }
                    WatchInfoRow("Deck", value: summary.halfDeck ? "Half" : "Full")
                    WatchInfoRow(label: "Difficulty") {
                        Text(multiplier(summary.difficulty)).font(WatchType.mono(12))
                    }
                }
                WatchActionButton(title: "Done") { model.finish() }
                    .handGestureShortcut(.primaryAction)
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(
            RadialGradient(colors: [DS.Colors.goldSoft, .black], center: .top, startRadius: 0, endRadius: 160)
                .ignoresSafeArea()
        )
    }
}

#Preview("Summary") {
    SummaryScreen(summary: .preview)
        .environment(WatchWorkoutModel())
}

extension WatchWorkoutSummary {
    static var preview: WatchWorkoutSummary {
        WatchWorkoutSummary(endedEarly: false, reps: 412, cardsCompleted: 54, deckSize: 54,
                            duration: 27 * 60 + 40, difficulty: .standard, halfDeck: false)
    }
}
