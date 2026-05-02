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
            .fill(faceUp ? Color(hex: "#FEFEFE") : Color(hex: "#1A1A22"))
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
                        colors: [Color(hex: "#1A1A22"), Color(hex: "#0E0E16")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Inner inset border
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DS.Colors.border.opacity(0.5), lineWidth: 1)
                .padding(8)

            // Outer border
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(DS.Colors.border, lineWidth: 1.5)

            // Circle border around "54"
            Circle()
                .strokeBorder(DS.Colors.gold.opacity(0.4), lineWidth: 1.5)
                .frame(width: 72, height: 72)

            // "54" label
            Text("54")
                .font(.custom("BarlowCondensed-ExtraBold", size: 40))
                .foregroundStyle(DS.Colors.gold)

            // Corner dots
            cornerDots
        }
    }

    private var cornerDots: some View {
        GeometryReader { geo in
            let inset: CGFloat = 14
            let dotSize: CGFloat = 5
            Group {
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: inset, y: inset)
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: geo.size.width - inset, y: inset)
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: inset, y: geo.size.height - inset)
                Circle().fill(DS.Colors.gold.opacity(0.35)).frame(width: dotSize, height: dotSize)
                    .position(x: geo.size.width - inset, y: geo.size.height - inset)
            }
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

        return ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#FEFEFE"))
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)

            // Top-left pip
            pipCorner(rank: rank, glyph: glyph, inkColor: inkColor)
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Bottom-right pip (rotated 180° before being placed)
            pipCorner(rank: rank, glyph: glyph, inkColor: inkColor)
                .rotationEffect(.degrees(180))
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            // Center motif
            centerMotif(rank: rank, glyph: glyph, inkColor: inkColor)
        }
    }

    private func pipCorner(rank: Rank, glyph: String, inkColor: Color) -> some View {
        VStack(alignment: .center, spacing: -2) {
            Text(rank.displaySymbol)
                .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                .foregroundStyle(inkColor)
            Text(glyph)
                .font(.system(size: 16))
                .foregroundStyle(inkColor)
        }
    }

    @ViewBuilder
    private func centerMotif(rank: Rank, glyph: String, inkColor: Color) -> some View {
        if rank == .ace {
            // Ace: full-size centered glyph
            Text(glyph)
                .font(.system(size: 90))
                .foregroundStyle(inkColor)
        } else if rank.isFace {
            // Face cards: glyph / rank / glyph vertical stack
            VStack(spacing: 4) {
                Text(glyph)
                    .font(.system(size: 36))
                    .foregroundStyle(inkColor)
                Text(rank.displaySymbol)
                    .font(.custom("BarlowCondensed-ExtraBold", size: 40))
                    .foregroundStyle(inkColor)
                Text(glyph)
                    .font(.system(size: 36))
                    .foregroundStyle(inkColor)
            }
        } else {
            // Number cards: faint center glyph
            Text(glyph)
                .font(.system(size: 80))
                .foregroundStyle(inkColor.opacity(0.2))
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
