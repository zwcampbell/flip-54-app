import SwiftUI
import Flip54DesignSystem

/// One of the four big buttons on the Controls page (End, Pause, Skip, Guide).
struct ControlTile: View {
    enum Tone { case destructive, gold, neutral }

    let title: String
    let systemImage: String
    var tone: Tone = .neutral
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(iconColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 59)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
                Text(title.uppercased())
                    .font(WatchType.sub(11))
                    .tracking(0.75)
                    .foregroundStyle(DS.Colors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    private var fill: Color {
        switch tone {
        case .destructive: DS.Colors.redSoft
        case .gold:        DS.Colors.goldSoft
        case .neutral:     DS.Colors.bgCard
        }
    }

    private var iconColor: Color {
        switch tone {
        case .destructive: DS.Colors.red
        case .gold:        DS.Colors.gold
        case .neutral:     DS.Colors.textPrimary
        }
    }
}

/// One tick per card in the deck, green for each card already flipped.
struct DeckProgressTicks: View {
    let flipped: Int
    let total: Int
    var height: CGFloat = 13

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < flipped ? DS.Colors.success : DS.Colors.border)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("\(flipped) of \(total) cards flipped")
    }
}

/// A number over a small caps label, as in the summary's REPS / CARDS / TIME row.
struct SummaryStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(WatchType.mono(18))
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(WatchType.sub(9))
                .tracking(1)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Controls page") {
    Grid(horizontalSpacing: 6, verticalSpacing: 8) {
        GridRow {
            ControlTile(title: "End", systemImage: "xmark", tone: .destructive) {}
            ControlTile(title: "Pause", systemImage: "pause.fill", tone: .gold) {}
        }
        GridRow {
            ControlTile(title: "Skip", systemImage: "forward.end.fill") {}
            ControlTile(title: "Guide", systemImage: "questionmark.circle") {}
        }
    }
    .padding(.horizontal, WatchLayout.edge)
    .background(Color.black)
}

#Preview("Progress ticks + stats") {
    VStack(spacing: 14) {
        DeckProgressTicks(flipped: 12, total: 54)
        DeckProgressTicks(flipped: 20, total: 27)
        HStack(spacing: 4) {
            SummaryStat(value: "412", label: "Reps")
            SummaryStat(value: "54", label: "Cards")
            SummaryStat(value: "27:40", label: "Time")
        }
    }
    .padding(.horizontal, 14)
    .background(Color.black)
}
