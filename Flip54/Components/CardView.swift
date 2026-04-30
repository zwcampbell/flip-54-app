import SwiftUI
import Flip54Core

/// Production card renderer.
///
/// Attempts to load a real art asset via `CardImageProvider`. If none is found
/// (deck not yet integrated or artwork pending) it falls back to
/// `CardPlaceholderView` so every code path always renders something.
///
/// Usage:
/// ```swift
/// CardView(card: .standard(suit: .hearts, rank: .seven), faceUp: true, deckId: "standard")
/// ```
struct CardView: View {
    let card: Card
    let faceUp: Bool
    var deckId: String = "standard"

    // Match the placeholder's fixed dimensions
    static let cardWidth:  CGFloat = CardPlaceholderView.cardWidth
    static let cardHeight: CGFloat = CardPlaceholderView.cardHeight

    private var provider: CardImageProvider { CardImageProvider(deckId: deckId) }

    var body: some View {
        let a11yLabel = faceUp ? card.accessibilityLabel : Card.faceDownLabel
        if let artwork = provider.image(for: card, faceUp: faceUp) {
            artwork
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Self.cardWidth, height: Self.cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.65), radius: 20, x: 0, y: 10)
                .accessibilityLabel(a11yLabel)
        } else {
            CardPlaceholderView(card: card, faceUp: faceUp)
                .accessibilityLabel(a11yLabel)
        }
    }
}
