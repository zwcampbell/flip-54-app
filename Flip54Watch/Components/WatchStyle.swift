import SwiftUI
import Flip54Core
import Flip54DesignSystem

/// Watch-only type and layout tokens. Colours come from `DS.Colors`; sizes are
/// the Flip 54 canvas "Apple Watch" page halved (the canvas draws the 45 mm
/// watch at 2×, 396 × 484 px).
enum WatchType {
    static func display(_ size: CGFloat) -> Font { .custom("BarlowCondensed-ExtraBold", size: size) }
    static func sub(_ size: CGFloat) -> Font { .custom("Oswald-SemiBold", size: size) }
    static func mono(_ size: CGFloat) -> Font { .custom("IBMPlexMono-Medium", size: size) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
}

enum WatchLayout {
    /// Inset of full-width buttons and rows from the screen edge.
    static let edge: CGFloat = 7
    static let buttonHeight: CGFloat = 42
    static let rowRadius: CGFloat = 14
    /// Card face aspect ratio (width / height), from the 132 × 188 px canvas card.
    static let cardAspect: CGFloat = 132.0 / 188.0
}

extension Suit {
    var symbolName: String {
        switch self {
        case .hearts:   "suit.heart.fill"
        case .spades:   "suit.spade.fill"
        case .clubs:    "suit.club.fill"
        case .diamonds: "suit.diamond.fill"
        }
    }

    var inkColor: Color { color == .red ? DS.Colors.red : DS.Colors.bg }
}

extension Card {
    /// Ink colour for the rank and pips printed on the card face.
    var inkColor: Color { suit?.inkColor ?? DS.Colors.bg }

    /// Colour of the big rep count next to the card. Matches the iPhone:
    /// red suits print red, everything else (black suits, jokers) prints gold.
    var accentColor: Color {
        if let suit, suit.color == .red { return DS.Colors.red }
        return DS.Colors.gold
    }

    var accessibilityName: String {
        switch self {
        case .standard(let suit, let rank): "\(rank.rawValue.capitalized) of \(suit.rawValue)"
        case .joker: "Joker"
        }
    }
}

/// Formats seconds as `m:ss`.
func watchClock(_ seconds: Int) -> String {
    let s = max(0, seconds)
    return "\(s / 60):" + String(format: "%02d", s % 60)
}
