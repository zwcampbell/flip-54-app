import SwiftUI

enum DS {
    enum Colors {
        static let bg            = Color(hex: "#111111")
        static let bgRaised      = Color(hex: "#191919")
        static let bgCard        = Color(hex: "#1A1A1A")
        static let surface       = Color(hex: "#101010")
        static let border        = Color(hex: "#2A2A2A")
        static let borderSub     = Color(hex: "#1E1E1E")
        static let textPrimary   = Color(hex: "#FEFEFE")
        static let textSecondary = Color(hex: "#D1CDC9")
        static let textTertiary  = Color(hex: "#666460")
        static let cardFace      = Color(hex: "#FEFEFE")
        static let red           = Color(hex: "#C8262C")
        static let redSoft       = Color(hex: "#2A1214")
        static let gold          = Color(hex: "#D1C4B1")
        static let goldSoft      = Color(hex: "#1E1B16")
        static let goldLight     = Color(hex: "#F0EAE0")
        static let neutral       = Color(hex: "#D1CDC9")
        static let success       = Color(hex: "#4CAF6E")
        static let urgent        = Color(hex: "#E8543C")
        static let white         = Color(hex: "#FEFEFE")
    }

    enum Typography {
        // Display — Barlow Condensed ExtraBold (maps to Futura Extra Bold Condensed in spec)
        static func display(_ text: String, size: CGFloat = 50) -> some View {
            Text(text)
                .font(.custom("BarlowCondensed-ExtraBold", size: size))
        }
        // Subheading — Oswald SemiBold (maps to Trade Gothic in spec)
        static func sub(_ text: String, size: CGFloat = 34) -> some View {
            Text(text)
                .font(.custom("Oswald-SemiBold", size: size))
        }
        // Body — system Helvetica
        static func body(_ text: String, size: CGFloat = 18) -> some View {
            Text(text)
                .font(.system(size: size, weight: .regular, design: .default))
        }
        // Monospace — IBM Plex Mono
        static func mono(_ text: String, size: CGFloat = 14) -> some View {
            Text(text)
                .font(.custom("IBMPlexMono-Medium", size: size))
        }
        // Caption
        static func caption(_ text: String, size: CGFloat = 13) -> some View {
            Text(text)
                .font(.system(size: size, weight: .regular))
        }
    }

    enum Layout {
        static let horizontalMargin: CGFloat = 24
        static let cornerRadius: CGFloat = 14
        static let buttonHeight: CGFloat = 56
        static let cardWidth: CGFloat = 280
        static let cardHeight: CGFloat = 392
        static let cardCornerRadius: CGFloat = 14
    }

    enum Shadow {
        static let card = Color.black.opacity(0.7)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
