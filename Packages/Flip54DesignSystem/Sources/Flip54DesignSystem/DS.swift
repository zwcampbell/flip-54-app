import SwiftUI

public enum DS {
    public enum Colors {
        public static let bg            = Color(hex: "#111111")
        public static let bgRaised      = Color(hex: "#191919")
        public static let bgCard        = Color(hex: "#1A1A1A")
        public static let surface       = Color(hex: "#101010")
        public static let border        = Color(hex: "#2A2A2A")
        public static let borderSub     = Color(hex: "#1E1E1E")
        public static let textPrimary   = Color(hex: "#FEFEFE")
        public static let textSecondary = Color(hex: "#D1CDC9")
        public static let textTertiary  = Color(hex: "#666460")
        public static let cardFace      = Color(hex: "#FEFEFE")
        public static let red           = Color(hex: "#C8262C")
        public static let redSoft       = Color(hex: "#2A1214")
        public static let gold          = Color(hex: "#D1C4B1")
        public static let goldSoft      = Color(hex: "#1E1B16")
        public static let goldLight     = Color(hex: "#F0EAE0")
        public static let neutral       = Color(hex: "#D1CDC9")
        public static let success       = Color(hex: "#4CAF6E")
        public static let urgent        = Color(hex: "#E8543C")
        public static let white         = Color(hex: "#FEFEFE")
    }

    public enum Typography {
        // Display — Barlow Condensed ExtraBold (maps to Futura Extra Bold Condensed in spec)
        // Returns `Text` (not `some View`) so callers can still chain Text-only
        // modifiers like `.tracking`/`letterSpacing`, as MidasBackView does.
        public static func display(_ text: String, size: CGFloat = 50) -> Text {
            Text(text)
                .font(.custom("BarlowCondensed-ExtraBold", size: size))
        }
        // Subheading — Oswald SemiBold (maps to Trade Gothic in spec)
        public static func sub(_ text: String, size: CGFloat = 34) -> some View {
            Text(text)
                .font(.custom("Oswald-SemiBold", size: size))
        }
        // Body — system Helvetica
        public static func body(_ text: String, size: CGFloat = 18) -> some View {
            Text(text)
                .font(.system(size: size, weight: .regular, design: .default))
        }
        // Monospace — IBM Plex Mono
        public static func mono(_ text: String, size: CGFloat = 14) -> some View {
            Text(text)
                .font(.custom("IBMPlexMono-Medium", size: size))
        }
        // Caption
        public static func caption(_ text: String, size: CGFloat = 13) -> some View {
            Text(text)
                .font(.system(size: size, weight: .regular))
        }
    }

    public enum Layout {
        public static let horizontalMargin: CGFloat = 24
        public static let cornerRadius: CGFloat = 14
        public static let buttonHeight: CGFloat = 56
        public static let cardWidth: CGFloat = 280
        public static let cardHeight: CGFloat = 392
        public static let cardCornerRadius: CGFloat = 14
    }

    public enum Shadow {
        public static let card = Color.black.opacity(0.7)
    }
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
