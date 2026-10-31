import SwiftUI
import Flip54DesignSystem

/// Countdown ring shown while an Ace hold is running.
struct HoldTimerRing: View {
    let remaining: Int
    let total: Int
    var diameter: CGFloat = 140
    /// Paused holds dim the ring and swap the "of" line for a pause glyph.
    var paused = false

    private var fraction: Double { total > 0 ? Double(remaining) / Double(total) : 0 }

    var body: some View {
        ZStack {
            Circle().stroke(DS.Colors.goldSoft, lineWidth: 9)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(DS.Colors.gold, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(paused ? 0.45 : 1)
            VStack(spacing: 3) {
                Text(watchClock(remaining))
                    .font(WatchType.mono(38))
                    .tracking(-0.5)
                    .foregroundStyle(paused ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                    .contentTransition(.numericText(countsDown: true))
                if paused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.gold)
                        .frame(height: 15)
                } else {
                    Text("OF \(watchClock(total))")
                        .font(WatchType.sub(11))
                        .tracking(1)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
        .padding(4.5)
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(paused
            ? "Hold paused, \(watchClock(remaining)) remaining"
            : "\(watchClock(remaining)) of \(watchClock(total)) remaining")
    }
}

/// Green check shown when a hold finishes.
struct HoldCompleteBadge: View {
    var diameter: CGFloat = 98

    var body: some View {
        ZStack {
            Circle().stroke(DS.Colors.success, lineWidth: 8)
            Image(systemName: "checkmark")
                .font(.system(size: diameter * 0.42, weight: .heavy))
                .foregroundStyle(DS.Colors.success)
        }
        .padding(4)
        .frame(width: diameter, height: diameter)
        .accessibilityLabel("Hold complete")
    }
}

#Preview("Holding, 0:45 of 1:00") {
    HoldTimerRing(remaining: 45, total: 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Hold paused, 0:45") {
    HoldTimerRing(remaining: 45, total: 60, paused: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Hold complete") {
    HoldCompleteBadge()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
