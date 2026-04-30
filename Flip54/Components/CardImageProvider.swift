import SwiftUI
import Flip54Core

/// Maps a `Card` + deck identifier to an optional bundled image asset.
///
/// Asset naming convention (inside `Resources/decks/{deckId}/`):
///   - `{deckId}-back`           Card back
///   - `{deckId}-{rank}-{suit}`  Standard cards  e.g. `standard-7-hearts`
///   - `{deckId}-joker-{variant}` Jokers          e.g. `standard-joker-red`
///
/// Returns nil when the asset is absent; callers should fall back to CardPlaceholderView.
struct CardImageProvider {
    let deckId: String

    func image(for card: Card, faceUp: Bool) -> Image? {
        let name: String
        if !faceUp {
            name = "\(deckId)-back"
        } else {
            switch card {
            case .standard(let suit, let rank):
                name = "\(deckId)-\(rank.rawValue)-\(suit.rawValue)"
            case .joker(let variant):
                name = "\(deckId)-joker-\(variant.rawValue)"
            }
        }
        guard UIImage(named: name) != nil else { return nil }
        return Image(name)
    }
}
