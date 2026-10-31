import SwiftUI
import Flip54DesignSystem

/// A face-down card: dark back, gold crosshatch panel and the "54" medallion.
struct WatchCardBack: View {
    var width: CGFloat = 75
    /// Soft gold halo used for the card waiting to be flipped.
    var glows = true

    private var scale: CGFloat { width / 75 }
    private var height: CGFloat { width * 214 / 150 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .fill(DS.Colors.bgCard)
                .strokeBorder(DS.Colors.border, lineWidth: 1)
                .shadow(color: DS.Shadow.card, radius: 16 * scale, y: 4 * scale)
                .shadow(color: glows ? DS.Colors.gold.opacity(0.14) : .clear, radius: 16 * scale)

            RoundedRectangle(cornerRadius: 4.5 * scale, style: .continuous)
                .fill(DS.Colors.bgCard)
                .overlay(Crosshatch(spacing: 6.5 * scale).stroke(DS.Colors.gold.opacity(0.08), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4.5 * scale, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4.5 * scale, style: .continuous)
                        .strokeBorder(DS.Colors.gold.opacity(0.35), lineWidth: 0.75)
                )
                .padding(4.5 * scale)

            Text("54")
                .font(WatchType.display(16 * scale))
                .foregroundStyle(DS.Colors.bg)
                .frame(width: 33 * scale, height: 33 * scale)
                .background(Circle().fill(DS.Colors.gold))
                .background(Circle().fill(DS.Colors.bgCard).padding(-3.5 * scale))
        }
        .frame(width: width, height: height)
        .accessibilityElement()
        .accessibilityLabel("Face-down card")
    }
}

/// Diagonal lines both ways, `spacing` apart.
private struct Crosshatch: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var offset: CGFloat = -rect.height
        while offset < rect.width {
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.minY))
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.maxY))
            offset += spacing
        }
        return path
    }
}

/// The three-card fan on the Start screen.
struct WatchDeckFan: View {
    var body: some View {
        ZStack {
            WatchCardBack(width: 50, glows: false)
                .rotationEffect(.degrees(-13), anchor: UnitPoint(x: 0.5, y: 0.92))
            WatchCardBack(width: 50, glows: false)
                .rotationEffect(.degrees(13), anchor: UnitPoint(x: 0.5, y: 0.92))
            WatchCardBack(width: 50)
                .offset(y: -3)
        }
        .accessibilityHidden(true)
    }
}

#Preview("Face-down card") {
    WatchCardBack()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Deck fan") {
    WatchDeckFan()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
