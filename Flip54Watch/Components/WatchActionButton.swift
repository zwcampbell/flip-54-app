import SwiftUI
import Flip54DesignSystem

/// Full-width pill at the bottom of a workout screen (Start, Flip, Done,
/// Start hold). Primary buttons carry the Double Tap glyph because they are
/// what the Double Tap gesture triggers.
struct WatchActionButton: View {
    enum Kind { case primary, destructive }

    let title: String
    var kind: Kind = .primary
    /// Overrides the default glyph (Double Tap for primary, xmark for destructive).
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: kind == .primary ? 6 : 5) {
                Image(systemName: glyph)
                    .font(.system(size: kind == .primary ? 14 : 12, weight: .bold))
                    .foregroundStyle(kind == .destructive ? DS.Colors.red : DS.Colors.bg)
                Text(title)
                    .font(WatchType.display(kind == .primary ? 18 : 16))
                    .tracking(kind == .primary ? 1 : 0.75)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(kind == .destructive ? DS.Colors.textPrimary : DS.Colors.bg)
            .frame(maxWidth: .infinity)
            .frame(height: WatchLayout.buttonHeight)
            .background(Capsule().fill(kind == .destructive ? DS.Colors.redSoft : DS.Colors.gold))
            .shadow(color: kind == .primary ? DS.Colors.gold.opacity(0.25) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
    }

    private var glyph: String {
        systemImage ?? (kind == .primary ? "hand.tap.fill" : "xmark")
    }
}

#Preview("Primary") {
    VStack {
        Spacer()
        WatchActionButton(title: "Flip") {}
    }
    .padding(.horizontal, WatchLayout.edge)
    .background(Color.black)
}

#Preview("Paused: End + Resume") {
    VStack {
        Spacer()
        HStack(spacing: 6) {
            WatchActionButton(title: "End", kind: .destructive) {}
            WatchActionButton(title: "Resume", systemImage: "play.fill") {}
        }
    }
    .padding(.horizontal, WatchLayout.edge)
    .background(Color.black)
}
