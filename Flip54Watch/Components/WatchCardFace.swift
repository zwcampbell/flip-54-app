import SwiftUI
import Flip54Core
import Flip54DesignSystem

/// A face-up playing card. Number and face cards show a faint centre pip,
/// Aces a full-strength one, face cards a gold inner frame, jokers a gold star.
struct WatchCardFace: View {
    let card: Card
    var width: CGFloat = 66

    private var scale: CGFloat { width / 66 }
    private var height: CGFloat { width / WatchLayout.cardAspect }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .fill(DS.Colors.cardFace)
                .shadow(color: DS.Shadow.card, radius: 8 * scale, y: 4 * scale)
                .shadow(color: card.isJoker ? DS.Colors.gold.opacity(0.28) : .clear, radius: 14 * scale)

            if card.isFaceCard {
                RoundedRectangle(cornerRadius: 3 * scale)
                    .strokeBorder(DS.Colors.gold, lineWidth: 0.75 * scale)
                    .padding(.horizontal, 19 * scale)
                    .padding(.vertical, 11 * scale)
            }

            centre
            corner.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            corner.rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .foregroundStyle(card.inkColor)
        .frame(width: width, height: height)
        .accessibilityElement()
        .accessibilityLabel(card.accessibilityName)
    }

    @ViewBuilder private var centre: some View {
        switch card {
        case .standard(let suit, let rank):
            Image(systemName: suit.symbolName)
                .font(.system(size: (rank == .ace ? 26 : rank.isFace ? 22 : 28) * scale))
                .opacity(rank == .ace ? 1 : 0.28)
        case .joker:
            VStack(spacing: 3 * scale) {
                Image(systemName: "star.fill")
                    .font(.system(size: 28 * scale))
                    .foregroundStyle(DS.Colors.gold)
                    .shadow(color: DS.Colors.bg, radius: 0.5)
                Text("JOKER")
                    .font(WatchType.sub(7.5 * scale))
                    .tracking(1.5 * scale)
                    .foregroundStyle(DS.Colors.bg)
            }
        }
    }

    @ViewBuilder private var corner: some View {
        VStack(spacing: 2.5 * scale) {
            switch card {
            case .standard(let suit, let rank):
                Text(rank.displaySymbol)
                    .font(WatchType.display(20 * scale))
                    .frame(height: 16 * scale)
                Image(systemName: suit.symbolName)
                    .font(.system(size: 9 * scale))
            case .joker:
                Image(systemName: "star.fill")
                    .font(.system(size: 10 * scale))
            }
        }
        .padding(.leading, 5 * scale)
        .padding(.top, 5.5 * scale)
        .accessibilityHidden(true)
    }
}

#Preview("Number, face, ace, joker") {
    HStack(spacing: 6) {
        WatchCardFace(card: .standard(suit: .hearts, rank: .seven), width: 40)
        WatchCardFace(card: .standard(suit: .spades, rank: .king), width: 40)
        WatchCardFace(card: .standard(suit: .diamonds, rank: .ace), width: 40)
        WatchCardFace(card: .joker(variant: .red), width: 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Full size, clubs ten") {
    WatchCardFace(card: .standard(suit: .clubs, rank: .ten))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
