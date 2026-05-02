import SwiftUI
import Flip54Core

struct CompletionView: View {
    let data: CompletedWorkoutData
    let onDone: () -> Void

    @State private var particles: [Particle] = []
    @State private var show = false

    private enum ConfettiShape { case circle, rect, triangle }

    private struct Particle: Identifiable {
        let id: Int
        let x: CGFloat
        let size: CGFloat
        let color: Color
        let delay: Double
        let duration: Double
        let finalY: CGFloat
        let rotation: Double
        let shape: ConfettiShape
    }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            // Confetti
            ForEach(particles) { p in
                confettiPiece(p)
                    .allowsHitTesting(false)
            }

            // Content
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    statsCard
                        .opacity(show ? 1 : 0)
                        .offset(y: show ? 0 : 30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.25), value: show)
                    actionButtons
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            buildParticles()
            withAnimation(.easeOut(duration: 0.4)) { show = true }
            HapticEngine.shared.play(.completion)
        }
    }

    @ViewBuilder
    private func confettiPiece(_ p: Particle) -> some View {
        switch p.shape {
        case .circle:
            Circle()
                .fill(p.color)
                .frame(width: p.size, height: p.size)
                .position(x: p.x, y: -20)
                .modifier(ConfettiFallModifier(finalY: p.finalY, delay: p.delay, duration: p.duration))
        case .rect:
            RoundedRectangle(cornerRadius: 2)
                .fill(p.color)
                .frame(width: p.size * 0.5, height: p.size)
                .position(x: p.x, y: -20)
                .rotationEffect(.degrees(p.rotation))
                .modifier(ConfettiFallModifier(finalY: p.finalY, delay: p.delay, duration: p.duration))
        case .triangle:
            Path { path in
                path.move(to: CGPoint(x: 0, y: p.size))
                path.addLine(to: CGPoint(x: p.size * 0.5, y: 0))
                path.addLine(to: CGPoint(x: p.size, y: p.size))
                path.closeSubpath()
            }
            .fill(p.color)
            .frame(width: p.size, height: p.size)
            .position(x: p.x, y: -20)
            .rotationEffect(.degrees(p.rotation))
            .modifier(ConfettiFallModifier(finalY: p.finalY, delay: p.delay, duration: p.duration))
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("🎉")
                .font(.system(size: 52))
                .scaleEffect(show ? 1 : 0.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: show)

            Group {
                Text("DECK\n")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 52))
                + Text("CLEARED.")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 52))
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(DS.Colors.textPrimary)
            .lineSpacing(-4)

            Text("54 cards. Every single one.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .padding(.top, 52)
        .padding(.bottom, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RadialGradient(
                colors: [DS.Colors.goldSoft, DS.Colors.bg.opacity(0)],
                center: .top,
                startRadius: 0,
                endRadius: 300
            )
        )
    }

    // MARK: - Stats card

    private var statsCard: some View {
        VStack(spacing: 0) {
            // Top row: totalReps, cards, time
            HStack {
                statCell(value: "\(data.totalReps)", label: "Total Reps")
                Divider().background(DS.Colors.border).frame(height: 44)
                statCell(value: "\(data.cardCount)", label: "Cards")
                Divider().background(DS.Colors.border).frame(height: 44)
                statCell(value: durationString, label: "Time")
            }
            .padding(.vertical, 16)

            Divider().background(DS.Colors.border)

            // Per-suit rows
            suitRow(suit: .hearts,   label: "Lower Body")
            Divider().background(DS.Colors.borderSub).padding(.leading, 50)
            suitRow(suit: .spades,   label: "Upper Body")
            Divider().background(DS.Colors.borderSub).padding(.leading, 50)
            suitRow(suit: .clubs,    label: "Total Body")
            Divider().background(DS.Colors.borderSub).padding(.leading, 50)
            suitRow(suit: .diamonds, label: "Core")

            if data.jumpingJacks > 0 {
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                jokerRow
            }
        }
        .background(DS.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(DS.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                .foregroundStyle(DS.Colors.textPrimary)
            Text(label.uppercased())
                .font(.custom("Oswald-SemiBold", size: 10))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func suitRow(suit: Suit, label: String) -> some View {
        let isRed = suit == .hearts || suit == .diamonds
        let glyph: String
        switch suit {
        case .hearts:   glyph = "♥"
        case .spades:   glyph = "♠"
        case .clubs:    glyph = "♣"
        case .diamonds: glyph = "♦"
        }

        return HStack(spacing: 14) {
            Text(glyph)
                .font(.system(size: 16))
                .foregroundStyle(isRed ? DS.Colors.red : DS.Colors.textPrimary)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            Text("\(data.repsBySuit[suit] ?? 0)")
                .font(.custom("IBMPlexMono-Medium", size: 14))
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }

    private var jokerRow: some View {
        HStack(spacing: 14) {
            Text("★")
                .font(.system(size: 16))
                .foregroundStyle(DS.Colors.gold)
                .frame(width: 20)
            Text("Jumping Jacks")
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            Text("\(data.jumpingJacks)")
                .font(.custom("IBMPlexMono-Medium", size: 14))
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }

    // MARK: - Action buttons

    @State private var showSharePlaceholder = false

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onDone) {
                Text("DONE")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                    .foregroundStyle(Color(hex: "#111111"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(DS.Colors.gold)
                    .clipShape(Capsule())
                    .shadow(color: DS.Colors.gold.opacity(0.25), radius: 12)
            }

            Button {
                showSharePlaceholder = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                    Text("SHARE RESULT")
                        .font(.custom("BarlowCondensed-ExtraBold", size: 20))
                }
                .foregroundStyle(DS.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(DS.Colors.bgCard)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(DS.Colors.border, lineWidth: 1.5))
            }
        }
        .opacity(show ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.5), value: show)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 48)
        .alert("Share coming soon", isPresented: $showSharePlaceholder) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Full share card with your stats is coming in a future update.")
        }
    }

    // MARK: - Helpers

    private var durationString: String {
        let total = Int(data.duration)
        let m = total / 60
        let s = total % 60
        let sStr = s < 10 ? "0\(s)" : "\(s)"
        return "\(m):\(sStr)"
    }

    private func buildParticles() {
        let colors: [Color] = [
            DS.Colors.gold, DS.Colors.red, DS.Colors.success,
            Color(hex: "#D4712A"), Color(hex: "#C9A832"),
            Color(hex: "#8B5CF6"), Color(hex: "#2E90FA"), .white
        ]
        let shapes: [ConfettiShape] = [.circle, .rect, .triangle]
        particles = (0..<240).map { i in
            Particle(
                id: i,
                x: CGFloat.random(in: 20...370),
                size: CGFloat.random(in: 5...13),
                color: colors[i % colors.count],
                delay: Double.random(in: 0...2.0),
                duration: Double.random(in: 1.4...2.8),
                finalY: CGFloat.random(in: 650...820),
                rotation: Double.random(in: 0...360),
                shape: shapes[i % shapes.count]
            )
        }
    }
}

// MARK: - Confetti fall modifier

private struct ConfettiFallModifier: ViewModifier {
    let finalY: CGFloat
    let delay: Double
    let duration: Double

    @State private var fallen = false

    func body(content: Content) -> some View {
        content
            .opacity(fallen ? 0 : 1)
            .offset(y: fallen ? finalY : 0)
            .onAppear {
                withAnimation(
                    .easeIn(duration: duration)
                    .delay(delay)
                ) {
                    fallen = true
                }
            }
    }
}

// Type-erased shape helper for conditional clipping
private struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { shape.path(in: $0) }
    }

    func path(in rect: CGRect) -> Path { _path(rect) }
}
