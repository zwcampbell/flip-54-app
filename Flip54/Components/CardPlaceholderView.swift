import SwiftUI
import Flip54Core

/// Prototype-quality card renderer. Milestone 5 replaces this with full art.
struct CardPlaceholderView: View {
    let card: Card
    let faceUp: Bool

    static let cardWidth: CGFloat  = 200
    static let cardHeight: CGFloat = 280   // ≈ 2.5 : 3.5 ratio

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(faceUp ? Color(hex: "#FEFEFE") : DS.Colors.bgCard)
            .frame(width: Self.cardWidth, height: Self.cardHeight)
            .overlay {
                if faceUp { faceUpOverlay } else { faceDownOverlay }
            }
            .shadow(color: .black.opacity(0.65), radius: 20, x: 0, y: 10)
    }

    // MARK: - Face down

    private var faceDownOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [DS.Colors.bgCard, DS.Colors.bgRaised],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(DS.Colors.border, lineWidth: 1.5)
            Text("54")
                .font(.custom("BarlowCondensed-ExtraBold", size: 52))
                .foregroundStyle(DS.Colors.gold)
        }
    }

    // MARK: - Face up

    @ViewBuilder
    private var faceUpOverlay: some View {
        switch card {
        case .joker:
            jokerFace
        case .standard(let suit, let rank):
            standardFace(suit: suit, rank: rank)
        }
    }

    private var jokerFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#FEFEFE"))
            VStack(spacing: 6) {
                Text("★")
                    .font(.system(size: 72))
                    .foregroundStyle(DS.Colors.gold)
                Text("JOKER")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                    .foregroundStyle(DS.Colors.gold)
            }
        }
    }

    private func standardFace(suit: Suit, rank: Rank) -> some View {
        let isRed = suit == .hearts || suit == .diamonds
        let inkColor: Color = isRed ? DS.Colors.red : Color(hex: "#111111")
        let glyph = suitGlyph(suit)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#FEFEFE"))
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)

            // Corner pip — top-left
            VStack(alignment: .leading, spacing: -2) {
                Text(rank.displaySymbol)
                    .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                    .foregroundStyle(inkColor)
                Text(glyph)
                    .font(.system(size: 16))
                    .foregroundStyle(inkColor)
            }
            .padding(10)

            // Center motif
            Text(glyph)
                .font(.system(size: 80))
                .foregroundStyle(inkColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func suitGlyph(_ suit: Suit) -> String {
        switch suit {
        case .hearts:   return "♥"
        case .spades:   return "♠"
        case .clubs:    return "♣"
        case .diamonds: return "♦"
        }
    }
}
