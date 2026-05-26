import SwiftUI

// MARK: - MidasSparklesView

/// 14 gold sparkle particles that scatter from the gilding origin during the
/// 'gilding' phase. Matches the <Sparkles> component in Flip 54 Midas Touch.html.
///
/// Each particle follows `@keyframes sparkleDrift`:
///   0%:   translate(0,0) scale(0), opacity 0
///   30%:  translate(dx,dy) scale(1), opacity 1
///   100%: translate(dx*1.6, dy*1.6 + 40px) scale(0.2), opacity 0
struct MidasSparklesView: View {
    /// Origin in card-local coordinates (where the gilding touch point is).
    var originX: CGFloat = CardPlaceholderView.cardWidth  / 2
    var originY: CGFloat = CardPlaceholderView.cardHeight / 2

    private struct Spark {
        let dx: CGFloat
        let dy: CGFloat
        let delay: TimeInterval
        let duration: TimeInterval
        let size: CGFloat
    }

    private let sparks: [Spark] = {
        let count = 14
        return (0..<count).map { i in
            let angle = (Double.pi * 2 * Double(i)) / Double(count)
                      + Double.random(in: 0...0.5)
            let r = CGFloat.random(in: 40...120)
            return Spark(
                dx:       CGFloat(cos(angle)) * r,
                dy:       CGFloat(sin(angle)) * r,
                delay:    Double.random(in: 0...0.8),
                duration: Double.random(in: 1.1...1.7),
                size:     CGFloat.random(in: 3...6)
            )
        }
    }()

    private let startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
            Canvas { drawCtx, _ in
                let now = ctx.date.timeIntervalSince(startDate)

                for s in sparks {
                    let t = now - s.delay
                    guard t > 0 else { continue }
                    let progress = min(1.0, t / s.duration)  // 0 → 1

                    // Position: linear interpolation of the three keyframes
                    let tx: CGFloat
                    let ty: CGFloat
                    let scale: CGFloat
                    let opacity: CGFloat

                    if progress < 0.3 {
                        // 0% → 30%: drift to (dx, dy), scale 0 → 1, opacity 0 → 1
                        let p = progress / 0.3
                        tx      = s.dx * CGFloat(p)
                        ty      = s.dy * CGFloat(p)
                        scale   = CGFloat(p)
                        opacity = CGFloat(p)
                    } else {
                        // 30% → 100%: drift to (dx*1.6, dy*1.6+40), scale 1 → 0.2, opacity 1 → 0
                        let p   = (progress - 0.3) / 0.7
                        let pp  = CGFloat(p)
                        tx      = s.dx + (s.dx * 0.6) * pp
                        ty      = s.dy + (s.dy * 0.6 + 40) * pp
                        scale   = 1.0 - 0.8 * pp
                        opacity = 1.0 - pp
                    }

                    guard opacity > 0 else { continue }

                    let x = originX + tx
                    let y = originY + ty
                    let r = s.size / 2 * scale

                    drawCtx.withCGContext { cg in
                        cg.saveGState()
                        cg.setAlpha(CGFloat(opacity))
                        // radial-gradient(circle, #FFF6CC 0%, #F7DC8E 60%, transparent 100%)
                        // Approximated as a bright gold circle with glow
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        cg.setFillColor(CGColor(red: 0.969, green: 0.863, blue: 0.557, alpha: 1)) // #F7DC8E
                        cg.fillEllipse(in: rect)
                        // Inner highlight
                        let hr = r * 0.5
                        let hRect = CGRect(x: x - hr, y: y - hr, width: hr * 2, height: hr * 2)
                        cg.setFillColor(CGColor(red: 1.0, green: 0.965, blue: 0.8, alpha: 1)) // ~#FFF6CC
                        cg.fillEllipse(in: hRect)
                        cg.restoreGState()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - MidasImpactView

/// Impact effects fired when the falling gold card hits the "floor".
///
/// Shockwaves — two elliptical rings that expand outward from the impact point.
/// Dust puffs — 7 circles that rise and dissipate.
/// Gold burst — 18 rectangular fragments burst radially, fall under gravity.
///
/// All effects are timed from `startDate` = the moment of impact.
/// `impactY` is the card's floor contact Y in full-screen (ignoresSafeArea) coordinates.
struct MidasImpactView: View {
    let startDate: Date
    let impactY:   CGFloat

    private struct DustPuff {
        let xFrac:    CGFloat  // x offset as fraction of cardWidth
        let yOffset:  CGFloat  // y offset in points (negative = above impact point)
        let size:     CGFloat
        let delay:    Double   // seconds after impact
        let duration: Double
    }

    private static let dustPuffs: [DustPuff] = [
        DustPuff(xFrac: -0.38, yOffset: -14,  size: 70, delay: 0.00, duration: 1.10),
        DustPuff(xFrac:  0.40, yOffset: -16,  size: 72, delay: 0.01, duration: 1.10),
        DustPuff(xFrac: -0.10, yOffset: -40,  size: 50, delay: 0.01, duration: 0.95),
        DustPuff(xFrac:  0.12, yOffset: -42,  size: 52, delay: 0.02, duration: 0.95),
        DustPuff(xFrac: -0.30, yOffset: -70,  size: 64, delay: 0.03, duration: 1.00),
        DustPuff(xFrac:  0.32, yOffset: -72,  size: 66, delay: 0.04, duration: 1.00),
        DustPuff(xFrac:  0.00, yOffset: -100, size: 80, delay: 0.06, duration: 1.05),
    ]

    // Both rings fire at/just after impact so they burst out from under the card.
    private let primaryDelay:   Double = 0.00
    private let secondaryDelay: Double = 0.10

    // MARK: - Gold burst pieces

    private struct GoldPiece {
        let vx: CGFloat       // initial x velocity (pt/s)
        let vy: CGFloat       // initial y velocity (pt/s, negative = up)
        let rotSpeed: Double  // degrees/s
        let w: CGFloat
        let h: CGFloat
        let delay: Double     // seconds after impact
        let duration: Double  // lifespan in seconds
        let colorIdx: Int     // 0 = primary gold, 1 = bright gold, 2 = dark gold
    }

    // Fresh random pieces per view instance so every completion differs.
    private let goldPieces: [GoldPiece]

    init(startDate: Date, impactY: CGFloat) {
        self.startDate = startDate
        self.impactY   = impactY
        self.goldPieces = (0..<18).map { _ in
            // Burst centered on "straight up" (−π/2 in screen-space Y-down),
            // ±120° spread covers all upward directions plus wide sideways arcs.
            let spread = Double.random(in: -2.094...2.094)
            let angle  = -Double.pi / 2.0 + spread
            let speed  = CGFloat.random(in: 280...700)
            return GoldPiece(
                vx:       speed * CGFloat(cos(angle)),
                vy:       speed * CGFloat(sin(angle)),
                rotSpeed: Double.random(in: -600...600),
                w:        CGFloat.random(in: 5...11),
                h:        CGFloat.random(in: 11...24),
                delay:    Double.random(in: 0...0.10),
                duration: Double.random(in: 0.85...1.45),
                colorIdx: Int.random(in: 0...2)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let cx  = geo.size.width  / 2
            let cy  = impactY                  // card's floor contact in screen coords
            let cw  = CardPlaceholderView.cardWidth

            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { ctx in
                let elapsed = ctx.date.timeIntervalSince(startDate)
                Canvas { drawCtx, _ in
                    // ── Shockwave rings ────────────────────────────────────────
                    // Each ring: expands from scale(0.1, 0.06) → scale(16, 8) over 720ms
                    let rings: [(delay: Double, initW: CGFloat, maxScaleX: CGFloat, maxScaleY: CGFloat, borderOpacity: CGFloat)] = [
                        (primaryDelay,   36, 16, 8, 0.9),
                        (secondaryDelay, 26, 14, 7, 0.65),
                    ]
                    for ring in rings {
                        let t = elapsed - ring.delay
                        guard t > 0 else { continue }
                        let progress = min(1.0, t / 0.720)
                        // ease out: cubic-bezier(0.1, 0.7, 0.4, 1) ≈ sqrt
                        let eased    = 1.0 - pow(1.0 - progress, 2.0)
                        let scaleX   = CGFloat(0.1 + eased * (Double(ring.maxScaleX) - 0.1))
                        let scaleY   = CGFloat(0.06 + eased * (Double(ring.maxScaleY) - 0.06))
                        let opacity  = CGFloat(ring.borderOpacity * (1.0 - progress))

                        guard opacity > 0 else { continue }

                        let rw = ring.initW * scaleX
                        let rh = ring.initW * scaleY * 0.5   // squashed ellipse
                        let rect = CGRect(x: cx - rw / 2, y: cy - rh / 2, width: rw, height: rh)

                        drawCtx.withCGContext { cg in
                            cg.saveGState()
                            cg.setStrokeColor(CGColor(red: 1.0, green: 0.922, blue: 0.667, alpha: CGFloat(opacity)))
                            cg.setLineWidth(max(0.5, CGFloat(3 * (1 - progress))))
                            cg.strokeEllipse(in: rect)
                            cg.restoreGState()
                        }
                    }

                    // ── Dust puffs ─────────────────────────────────────────────
                    for dust in Self.dustPuffs {
                        let t = elapsed - dust.delay
                        guard t > 0 else { continue }
                        let progress = min(1.0, t / dust.duration)
                        // @keyframes dustRise: 0% scale(0.3), 18% opacity 0.7, 100% scale(1.7) opacity 0
                        let scale: CGFloat   = 0.3 + CGFloat(progress) * 1.4   // 0.3 → 1.7
                        let yRise: CGFloat   = -40 * CGFloat(progress)          // rises 40pt
                        let opacity: CGFloat
                        if progress < 0.18 {
                            opacity = CGFloat(progress / 0.18) * 0.7
                        } else {
                            opacity = 0.7 * (1.0 - CGFloat((progress - 0.18) / 0.82))
                        }
                        guard opacity > 0 else { continue }

                        let dx   = dust.xFrac * cw
                        let x    = cx + dx
                        let y    = cy + dust.yOffset + yRise
                        let r    = dust.size / 2 * scale

                        drawCtx.withCGContext { cg in
                            cg.saveGState()
                            cg.setAlpha(CGFloat(opacity))
                            // radial-gradient: rgba(190,180,160,0.6) centre, transparent at 75%
                            // Approximated as semi-transparent warm grey circle
                            cg.setFillColor(CGColor(red: 0.745, green: 0.706, blue: 0.627, alpha: 0.38))
                            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                            cg.fillEllipse(in: rect)
                            cg.restoreGState()
                        }
                    }

                    // ── Gold piece burst ───────────────────────────────────────
                    // Rectangular card-fragment pieces burst at impact and fall
                    // off-screen under gravity (1400 pt/s²).
                    let gravity: CGFloat = 1400
                    let pieceColors: [CGColor] = [
                        CGColor(red: 0.831, green: 0.635, blue: 0.298, alpha: 1), // #D4A24C
                        CGColor(red: 0.969, green: 0.863, blue: 0.557, alpha: 1), // #F7DC8E
                        CGColor(red: 0.722, green: 0.525, blue: 0.043, alpha: 1), // #B8860B
                    ]
                    for piece in goldPieces {
                        let t = CGFloat(elapsed - piece.delay)
                        guard t > 0 else { continue }
                        let life = min(1.0, Double(t) / piece.duration)
                        let x = cx + piece.vx * t
                        let y = cy + piece.vy * t + 0.5 * gravity * t * t
                        // Fade over final 45% of lifespan
                        let opacity: CGFloat = life < 0.55
                            ? 1.0
                            : CGFloat(1.0 - (life - 0.55) / 0.45)
                        guard opacity > 0 else { continue }
                        let rotation = CGFloat(piece.rotSpeed * Double(t) * .pi / 180.0)

                        drawCtx.withCGContext { cg in
                            cg.saveGState()
                            cg.translateBy(x: x, y: y)
                            cg.rotate(by: rotation)
                            cg.setAlpha(opacity)
                            cg.setFillColor(pieceColors[piece.colorIdx])
                            let rect = CGRect(x: -piece.w / 2, y: -piece.h / 2,
                                             width: piece.w, height: piece.h)
                            let path = CGPath(roundedRect: rect,
                                             cornerWidth: 1.5, cornerHeight: 1.5,
                                             transform: nil)
                            cg.addPath(path)
                            cg.fillPath()
                            cg.restoreGState()
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
