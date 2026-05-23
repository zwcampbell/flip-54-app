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
/// Matches the impact effects in Flip 54 Midas Touch.html:
///
/// Shockwaves — two elliptical rings that expand outward:
///   Primary:   fires at 68% of fall (≈ 646ms), expands from scale(0.1, 0.06) → scale(16, 8)
///   Secondary: fires at 79% of fall (≈ 750ms), slightly smaller
///
/// Dust puffs — 7 circles that rise and dissipate:
///   @keyframes dustRise: translate(-50%, 8px) scale(0.3) → translate(-50%, -32px) scale(1.7)
///
/// Position: centred on-screen at the card's landing point (below and forward of card).
struct MidasImpactView: View {
    let startDate: Date

    private static let fallDuration: Double = 0.950  // seconds

    private struct DustPuff {
        let xFrac:    CGFloat  // x offset as fraction of cardWidth
        let yOffset:  CGFloat  // y offset in points (negative = above)
        let size:     CGFloat
        let delayFrac: Double  // fraction of fall duration
        let duration:  Double  // ms → seconds
    }

    private static let dustPuffs: [DustPuff] = [
        DustPuff(xFrac: -0.38, yOffset: -14,  size: 70, delayFrac: 0.69, duration: 1.10),
        DustPuff(xFrac:  0.40, yOffset: -16,  size: 72, delayFrac: 0.70, duration: 1.10),
        DustPuff(xFrac: -0.30, yOffset: -70,  size: 64, delayFrac: 0.73, duration: 1.00),
        DustPuff(xFrac:  0.32, yOffset: -72,  size: 66, delayFrac: 0.74, duration: 1.00),
        DustPuff(xFrac:  0.00, yOffset: -100, size: 80, delayFrac: 0.76, duration: 1.05),
        DustPuff(xFrac: -0.10, yOffset: -40,  size: 50, delayFrac: 0.71, duration: 0.95),
        DustPuff(xFrac:  0.12, yOffset: -42,  size: 52, delayFrac: 0.72, duration: 0.95),
    ]

    // Absolute fire times within this view's own startDate timeline
    private var primaryDelay:   Double { Self.fallDuration * 0.68 }
    private var secondaryDelay: Double { Self.fallDuration * 0.79 }

    var body: some View {
        GeometryReader { geo in
            let cx  = geo.size.width  / 2
            let cy  = geo.size.height * 0.62   // approximate landing Y
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
                        let delay = Self.fallDuration * dust.delayFrac
                        let t     = elapsed - delay
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
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
