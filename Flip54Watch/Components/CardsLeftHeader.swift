import SwiftUI
import Flip54DesignSystem

/// Small green ring that fills as the deck is worked through.
struct CardsLeftRing: View {
    /// 0...1, fraction of the deck flipped.
    let progress: Double
    var diameter: CGFloat = 17
    var lineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle().stroke(DS.Colors.border, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Top-left status on the workout screens: ring + "42 LEFT".
struct CardsLeftHeader: View {
    let remaining: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            CardsLeftRing(progress: total > 0 ? Double(total - remaining) / Double(total) : 0)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(remaining)")
                    .font(WatchType.sub(15))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("LEFT")
                    .font(WatchType.sub(10))
                    .tracking(0.75)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(remaining) cards left")
    }
}

/// Page indicator for the workout's horizontal pages (Controls, Card, Now Playing).
struct WatchPageDots: View {
    let count: Int
    let selected: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == selected ? DS.Colors.textPrimary : Color(hex: "#4A4A4A"))
                    .frame(width: 4.5, height: 4.5)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Header + dots") {
    VStack(alignment: .leading, spacing: 12) {
        CardsLeftHeader(remaining: 42, total: 54)
        CardsLeftHeader(remaining: 3, total: 27)
        WatchPageDots(count: 3, selected: 1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
