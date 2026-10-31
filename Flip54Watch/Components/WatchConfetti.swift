import SwiftUI
import Flip54DesignSystem

/// Confetti that falls once over the summary when a deck is cleared. The
/// iPhone completion screen's burst, scaled down to the watch: fewer, smaller
/// pieces in the same colours and shapes. Skipped with Reduce Motion.
struct WatchConfetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces: [Piece] = []

    private enum Shape { case circle, rect, triangle }

    private struct Piece: Identifiable {
        let id: Int
        let x: CGFloat
        let size: CGFloat
        let color: Color
        let delay: Double
        let duration: Double
        let drift: CGFloat
        let rotation: Double
        let shape: Shape
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    view(for: piece)
                        .position(x: piece.x * geo.size.width, y: -10)
                        .modifier(Fall(distance: geo.size.height + 30, drift: piece.drift,
                                       delay: piece.delay, duration: piece.duration))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { if !reduceMotion { pieces = Self.makePieces() } }
    }

    @ViewBuilder private func view(for piece: Piece) -> some View {
        switch piece.shape {
        case .circle:
            Circle().fill(piece.color)
                .frame(width: piece.size, height: piece.size)
        case .rect:
            RoundedRectangle(cornerRadius: 1).fill(piece.color)
                .frame(width: piece.size * 0.5, height: piece.size)
                .rotationEffect(.degrees(piece.rotation))
        case .triangle:
            Path { path in
                path.move(to: CGPoint(x: 0, y: piece.size))
                path.addLine(to: CGPoint(x: piece.size * 0.5, y: 0))
                path.addLine(to: CGPoint(x: piece.size, y: piece.size))
                path.closeSubpath()
            }
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size)
            .rotationEffect(.degrees(piece.rotation))
        }
    }

    private static func makePieces() -> [Piece] {
        let colors: [Color] = [
            DS.Colors.gold, DS.Colors.red, DS.Colors.success,
            Color(hex: "#D4712A"), Color(hex: "#C9A832"),
            Color(hex: "#8B5CF6"), Color(hex: "#2E90FA"), .white
        ]
        let shapes: [Shape] = [.circle, .rect, .triangle]
        return (0..<70).map { i in
            Piece(
                id: i,
                x: CGFloat.random(in: 0.04...0.96),
                size: CGFloat.random(in: 4...8),
                color: colors[i % colors.count],
                delay: Double.random(in: 0...1.4),
                duration: Double.random(in: 1.8...3.0),
                drift: CGFloat.random(in: -14...14),
                rotation: Double.random(in: 0...360),
                shape: shapes[i % shapes.count]
            )
        }
    }

    private struct Fall: ViewModifier {
        let distance: CGFloat
        let drift: CGFloat
        let delay: Double
        let duration: Double
        @State private var fallen = false
        @State private var faded = false

        func body(content: Content) -> some View {
            content
                .offset(x: fallen ? drift : 0, y: fallen ? distance : 0)
                .opacity(faded ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: duration).delay(delay)) { fallen = true }
                    // Stay solid for most of the fall, fading out near the bottom.
                    withAnimation(.easeIn(duration: duration * 0.3).delay(delay + duration * 0.7)) { faded = true }
                }
        }
    }
}

#Preview {
    WatchConfetti()
        .background(Color.black)
}
