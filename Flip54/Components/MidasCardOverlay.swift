import SwiftUI
import Flip54Core

// MARK: - Palette (mirrors MIDAS object in midas-cards.jsx)

private enum MIDAS {
    static let goldHi   = Color(hex: "#F7DC8E")
    static let gold     = Color(hex: "#D4A24C")
    static let goldLo   = Color(hex: "#8B5E14")
    static let goldDeep = Color(hex: "#3D2A0A")
}

// MARK: - GrowingCircleMask

/// Animatable clip shape that expands from a fixed origin.
/// Drive `radius` from 0 → card diagonal to produce the Midas reveal.
struct GrowingCircleMask: Shape {
    var radius: CGFloat
    var centerX: CGFloat
    var centerY: CGFloat

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(
            x: centerX - radius,
            y: centerY - radius,
            width:  radius * 2,
            height: radius * 2
        ))
    }
}

// MARK: - MidasFaceView

/// Gold-leaf card face. Matches `MidasFace` in midas-cards.jsx exactly:
///   • GOLD_FACE_BG warm linear gradient (E9C176 → 5C3F0A)
///   • Diagonal guilloché stripes 45° at 7px stride, inset 4pt
///   • Static specular band at 115° (screen blend) — NOT animated
///   • Inset double border: 1.5pt #F7DC8E outer, 1pt #8B5E14 inner
///   • Corner pip + suit in engraved deep-gold (#3D2A0A) style
///   • Centre motif varies by card type
struct MidasFaceView: View {
    let card: Card
    var width:  CGFloat = CardPlaceholderView.cardWidth
    var height: CGFloat = CardPlaceholderView.cardHeight

    var body: some View {
        let fontSize   = width * 0.22
        let pipSize    = width * 0.18
        let centerSize = width * 0.42

        ZStack {
            goldBackground
            guillocheStripes
            staticShimmerBand
            cornerPip(flip: false, fontSize: fontSize, pipSize: pipSize)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 0))
            cornerPip(flip: true, fontSize: fontSize, pipSize: pipSize)
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 8))
            centreMotif(centerSize: centerSize, fontSize: fontSize)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        // inset 0 0 0 1.5px #F7DC8E, then inset 0 0 0 2.5px #8B5E14
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MIDAS.goldHi, lineWidth: 1.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(MIDAS.goldLo, lineWidth: 1.0)
                .padding(2)
        )
        // 0 12px 36px rgba(120,80,10,0.55), 0 2px 10px rgba(0,0,0,0.5)
        .shadow(color: Color(red: 0.47, green: 0.31, blue: 0.04).opacity(0.55), radius: 36, x: 0, y: 12)
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 2)
    }

    // MARK: - Layers

    /// GOLD_FACE_BG: linear-gradient(140deg, #E9C176 → #5C3F0A)
    private var goldBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#E9C176"), location: 0.00),
                        .init(color: Color(hex: "#D4A24C"), location: 0.28),
                        .init(color: Color(hex: "#B68628"), location: 0.58),
                        .init(color: Color(hex: "#8B5E14"), location: 0.88),
                        .init(color: Color(hex: "#5C3F0A"), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.20, y: 0.10),
                    endPoint:   UnitPoint(x: 0.90, y: 0.90)
                )
            )
    }

    /// repeating-linear-gradient(45deg, transparent 0–6px, rgba(80,55,10,0.06) 6–7px)
    /// Rendered with Canvas at 7pt stride, inset 4pt, clipped to rounded rect.
    private var guillocheStripes: some View {
        Canvas { ctx, size in
            let c = Color(hex: "#503710").opacity(0.06)
            var off: CGFloat = -size.height
            while off < size.width + size.height {
                var p = Path()
                p.move(to:    CGPoint(x: off,              y: 0))
                p.addLine(to: CGPoint(x: off + size.height, y: size.height))
                ctx.stroke(p, with: .color(c), lineWidth: 1)
                off += 7
            }
        }
        .padding(4)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .allowsHitTesting(false)
    }

    /// Static 115° specular band — gives the gold surface its sheen.
    /// linear-gradient(115deg, transparent 35%, rgba(255,247,210,0.35) 49%,
    ///   rgba(255,247,210,0.05) 52%, transparent 65%) — screen blend, NOT animated.
    private var staticShimmerBand: some View {
        LinearGradient(
            stops: [
                .init(color: .clear,                                   location: 0.35),
                .init(color: Color(hex: "#FFF7D2").opacity(0.35),      location: 0.49),
                .init(color: Color(hex: "#FFF7D2").opacity(0.05),      location: 0.52),
                .init(color: .clear,                                   location: 0.65),
            ],
            startPoint: UnitPoint(x: 0.0, y: 0.85),
            endPoint:   UnitPoint(x: 1.0, y: 0.15)
        )
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    // MARK: - Corner pip

    private func cornerPip(flip: Bool, fontSize: CGFloat, pipSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: -2) {
            Text(rankText)
                .font(.custom("BarlowCondensed-ExtraBold", size: fontSize))
                .foregroundStyle(MIDAS.goldDeep)
                .lineLimit(1)
            if !suitGlyph.isEmpty {
                Text(suitGlyph)
                    .font(.system(size: pipSize))
                    .foregroundStyle(MIDAS.goldDeep)
            }
        }
        .midasEngraved()
    }

    // MARK: - Centre motif

    @ViewBuilder
    private func centreMotif(centerSize: CGFloat, fontSize: CGFloat) -> some View {
        switch card {
        case .joker:
            // ★ + "MIDAS" label (Oswald, tracking 0.18em)
            VStack(spacing: 4) {
                Text("★")
                    .font(.system(size: centerSize * 0.75))
                    .foregroundStyle(MIDAS.goldDeep)
                Text("MIDAS")
                    .font(.custom("Oswald-Bold", size: fontSize * 0.55))
                    .foregroundStyle(MIDAS.goldDeep)
                    .tracking(fontSize * 0.55 * 0.18)
            }
            .midasEngraved()

        case .standard(let suit, let rank):
            let glyph = suitEmoji(suit)
            if rank == .ace {
                Text(glyph)
                    .font(.system(size: centerSize))
                    .foregroundStyle(MIDAS.goldDeep)
                    .midasEngraved()
            } else if rank.isFace {
                // glyph (×0.5) / rank (×1.5) / glyph (×0.35)
                VStack(spacing: 4) {
                    Text(glyph)
                        .font(.system(size: centerSize * 0.50))
                        .foregroundStyle(MIDAS.goldDeep)
                    Text(rank.displaySymbol)
                        .font(.custom("BarlowCondensed-ExtraBold", size: fontSize * 1.5))
                        .foregroundStyle(MIDAS.goldDeep)
                    Text(glyph)
                        .font(.system(size: centerSize * 0.35))
                        .foregroundStyle(MIDAS.goldDeep)
                }
                .midasEngraved()
            } else {
                // Number card: faint centre glyph at 0.32 opacity
                Text(glyph)
                    .font(.system(size: centerSize))
                    .foregroundStyle(MIDAS.goldDeep.opacity(0.32))
                    .midasEngraved()
            }
        }
    }

    // MARK: - Helpers

    private var rankText: String {
        switch card {
        case .joker:                    return "★"
        case .standard(_, let rank):   return rank.displaySymbol
        }
    }

    private var suitGlyph: String {
        switch card {
        case .joker:                    return ""
        case .standard(let suit, _):   return suitEmoji(suit)
        }
    }

    private func suitEmoji(_ suit: Suit) -> String {
        switch suit {
        case .hearts:   return "♥\u{FE0E}"
        case .spades:   return "♠\u{FE0E}"
        case .clubs:    return "♣\u{FE0E}"
        case .diamonds: return "♦\u{FE0E}"
        }
    }
}

// MARK: - Engraved text modifier

private extension View {
    /// Stamped gold-leaf shadow: bright top highlight + dark bottom shadow.
    /// textShadow: 0 1px 0 rgba(255,230,160,0.75), 0 -1px 0 rgba(60,40,0,0.55),
    ///             0 0 2px rgba(50,30,0,0.4)
    func midasEngraved() -> some View {
        self
            .shadow(color: Color(hex: "#FFE6A0").opacity(0.75), radius: 0, x: 0, y:  1)
            .shadow(color: Color(hex: "#3C2800").opacity(0.55), radius: 0, x: 0, y: -1)
            .shadow(color: Color(hex: "#321E00").opacity(0.40), radius: 2, x: 0, y:  0)
    }
}

// MARK: - MidasBackView

/// Ornate card back. Matches `MidasBack` in midas-cards.jsx exactly:
///   • Deep black-gold base with warm radial highlight
///   • Diagonal guilloché weave 45° + -45° at 6px stride, inset 12pt
///   • Conic sunburst: 24 primary (5°/15°) + 24 secondary (3°/15°) rays
///   • Inner double-line frame: 1pt #D4A24C at inset 6, 0.5pt #8B5E14 at inset 10
///   • Corner laurel ornaments (all 4 corners)
///   • Central flat-gold "54" medallion with concentric ring borders
///   • Outer rope frame: 1.5pt #8B5E14 + 1pt #3D2A0A inset
struct MidasBackView: View {
    var width:  CGFloat = CardPlaceholderView.cardWidth
    var height: CGFloat = CardPlaceholderView.cardHeight

    var body: some View {
        let medW = width * 0.55
        ZStack {
            backgroundGradient
            guillocheWeave
            conicSunburst
            // Inner frame: inset 6, 1px #D4A24C 0.55
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(MIDAS.gold.opacity(0.55), lineWidth: 1)
                .padding(6)
            // Inner frame: inset 10, 0.5px #8B5E14 0.5
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(MIDAS.goldLo.opacity(0.5), lineWidth: 0.5)
                .padding(10)
            cornerLaurels
            medallion(medW: medW)
            // Outer rope frame
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(MIDAS.goldLo, lineWidth: 1.5)
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(MIDAS.goldDeep, lineWidth: 1.0)
                .padding(1.5)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.7), radius: 36, x: 0, y: 12)
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 2)
    }

    // MARK: - Layers

    private var backgroundGradient: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#1F1608"), location: 0.00),
                        .init(color: Color(hex: "#0E0904"), location: 0.60),
                        .init(color: Color(hex: "#1A1208"), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.20, y: 0.10),
                    endPoint:   UnitPoint(x: 0.90, y: 0.90)
                )
            )
    }

    /// Both 45° and -45° stripes — creates a diamond weave.
    /// repeating-linear-gradient(45deg, transparent 0 5px, rgba(212,162,76,0.06) 5–6px)
    /// repeating-linear-gradient(-45deg, transparent 0 5px, rgba(212,162,76,0.06) 5–6px)
    /// inset: 12, borderRadius: card - 8 = 6
    private var guillocheWeave: some View {
        Canvas { ctx, size in
            let c = MIDAS.gold.opacity(0.06)
            var off: CGFloat = -size.height
            while off < size.width + size.height {
                var fwd = Path()
                fwd.move(to:    CGPoint(x: off,              y: 0))
                fwd.addLine(to: CGPoint(x: off + size.height, y: size.height))
                ctx.stroke(fwd, with: .color(c), lineWidth: 1)
                var bk = Path()
                bk.move(to:    CGPoint(x: off,             y: 0))
                bk.addLine(to: CGPoint(x: off - size.height, y: size.height))
                ctx.stroke(bk, with: .color(c), lineWidth: 1)
                off += 6
            }
        }
        .padding(12)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .allowsHitTesting(false)
    }

    /// Two-layer conic sunburst matching the CSS repeating-conic-gradient spec.
    /// Primary:   #D4A24C 0.45 opacity — rays 0°–5°, period 15°
    /// Secondary: #F7DC8E 0.35 opacity — rays 0°–3° offset +7.5°, period 15°
    private var conicSunburst: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2
            let r  = sqrt(cx * cx + cy * cy) + 8

            // Primary rays
            for i in 0..<24 {
                let s = (Double(i) * 15.0       - 90.0) * .pi / 180.0
                let e = (Double(i) * 15.0 + 5.0 - 90.0) * .pi / 180.0
                var path = Path()
                path.move(to: CGPoint(x: cx, y: cy))
                path.addArc(center: CGPoint(x: cx, y: cy),
                            radius: r, startAngle: .radians(s),
                            endAngle: .radians(e), clockwise: false)
                path.closeSubpath()
                ctx.fill(path, with: .color(MIDAS.gold.opacity(0.45)))
            }
            // Secondary rays
            for i in 0..<24 {
                let s = (Double(i) * 15.0 + 7.5       - 90.0) * .pi / 180.0
                let e = (Double(i) * 15.0 + 7.5 + 3.0 - 90.0) * .pi / 180.0
                var path = Path()
                path.move(to: CGPoint(x: cx, y: cy))
                path.addArc(center: CGPoint(x: cx, y: cy),
                            radius: r, startAngle: .radians(s),
                            endAngle: .radians(e), clockwise: false)
                path.closeSubpath()
                ctx.fill(path, with: .color(MIDAS.goldHi.opacity(0.35)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .allowsHitTesting(false)
    }

    // MARK: - Corner laurels

    private var cornerLaurels: some View {
        GeometryReader { geo in
            let configs: [(CGFloat, CGFloat, Double)] = [
                (0, 0,    0),
                (1, 0,   90),
                (0, 1,  -90),
                (1, 1,  180),
            ]
            ForEach(Array(configs.enumerated()), id: \.offset) { _, cfg in
                let (rx, ry, rot) = cfg
                let x = rx == 0 ? CGFloat(8) : geo.size.width  - 8
                let y = ry == 0 ? CGFloat(8) : geo.size.height - 8
                MidasLaurelView()
                    .rotationEffect(.degrees(rot))
                    .position(x: x, y: y)
            }
        }
    }

    // MARK: - Central medallion

    /// Flat gold disc — background: MIDAS.gold (no gradient).
    /// boxShadow: 0 0 0 1.5px #F7DC8E, 0 0 0 3px #3D2A0A (concentric ring borders).
    private func medallion(medW: CGFloat) -> some View {
        ZStack {
            // Outermost ring border (#3D2A0A) — spread 3px = 1.5pt each side
            Circle()
                .fill(MIDAS.goldDeep)
                .frame(width: medW + 6, height: medW + 6)
            // Inner ring border (#F7DC8E) — spread 1.5px = 0.75pt each side
            Circle()
                .fill(MIDAS.goldHi)
                .frame(width: medW + 3, height: medW + 3)
            // Gold disc (flat, no gradient)
            Circle()
                .fill(MIDAS.gold)
                .frame(width: medW, height: medW)
            Text("54")
                .font(.custom("BarlowCondensed-ExtraBold", size: medW * 0.42))
                .foregroundStyle(MIDAS.goldDeep)
                .letterSpacing(medW * 0.42 * 0.04)
        }
    }
}

// MARK: - MidasLaurelView

/// Triangular corner ornament. Matches JS: borderLeft/Right 7px transparent,
/// borderBottom 10px MIDAS.gold — produces an upward-pointing triangle.
/// Dot at left:5, top:6 within the 14×14 container → offset (0, +1) from ZStack centre.
private struct MidasLaurelView: View {
    var body: some View {
        ZStack {
            MidasTriangle()
                .fill(MIDAS.gold.opacity(0.85))
                .frame(width: 14, height: 10)
            Circle()
                .fill(MIDAS.goldHi.opacity(0.9))
                .frame(width: 4, height: 4)
                .offset(x: 0, y: 1)
        }
    }
}

private struct MidasTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - MidasGleamOverlay

/// Animated gleam shown on top of the gilded card during the 'gilded' and 'falling' phases.
/// Matches @keyframes midasGleam in Flip 54 Midas Touch.html:
///   0%,100%: translateX(-30%), opacity 0
///   50%:     translateX(+30%), opacity 1
///   Duration: 1.8s ease-in-out, repeating.
struct MidasGleamOverlay: View {
    var width:  CGFloat = CardPlaceholderView.cardWidth
    var height: CGFloat = CardPlaceholderView.cardHeight
    /// Fades the whole overlay to 0.6 during the falling phase (matches spec: opacity: 0.6).
    var fallingOpacity: Bool = false

    private let startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
            let elapsed = ctx.date.timeIntervalSince(startDate)
            let period  = 1.8
            // t goes 0 → 1 over one period
            let t = (elapsed.truncatingRemainder(dividingBy: period)) / period
            // translateX maps t∈[0,1] → [-30%, +30%] linearly
            let tx = (CGFloat(t) * 0.6 - 0.3) * width
            // opacity: sin curve peaks at t=0.5
            let op = sin(CGFloat(t) * .pi)
            LinearGradient(
                stops: [
                    .init(color: .clear,                              location: 0.40),
                    .init(color: Color(hex: "#FFF7D2").opacity(0.40), location: 0.50),
                    .init(color: .clear,                              location: 0.60),
                ],
                startPoint: UnitPoint(x: 0.0, y: 0.85),
                endPoint:   UnitPoint(x: 1.0, y: 0.15)
            )
            .offset(x: tx)
            .opacity(Double(op))
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(fallingOpacity ? 0.6 : 1.0)
        .allowsHitTesting(false)
    }
}

// MARK: - Text letter-spacing helper

private extension Text {
    func letterSpacing(_ value: CGFloat) -> Text {
        self.tracking(value)
    }
}
