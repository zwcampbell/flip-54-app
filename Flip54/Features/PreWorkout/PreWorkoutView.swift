import SwiftUI
import Flip54WorkoutEngine

struct PreWorkoutView: View {
    let coordinator: WorkoutCoordinator

    @State private var isShuffling = false

    private var isShufflingState: Bool {
        if case .shuffling = coordinator.state { return true }
        return false
    }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer()
                deckFanView
                Spacer()
                bottomBar
            }
        }
        .onChange(of: coordinator.state) { _, newState in
            if case .shuffling = newState {
                isShuffling = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    coordinator.send(.shuffleComplete)
                }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Standard Deck")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DS.Colors.bgCard)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(DS.Colors.border, lineWidth: 1))

            Spacer()

            Button { } label: {
                Text("?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.bgCard)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(DS.Colors.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Deck fan

    private struct CardOffset {
        let dx: CGFloat; let dy: CGFloat; let rot: Double
    }

    private let cardOffsets: [CardOffset] = [
        CardOffset(dx: -12, dy: -4, rot: -8),
        CardOffset(dx: -6,  dy: -2, rot: -4),
        CardOffset(dx:  0,  dy:  0, rot:  0),
        CardOffset(dx:  6,  dy: -2, rot:  4),
        CardOffset(dx: 12,  dy: -4, rot:  8),
    ]

    private var deckFanView: some View {
        ZStack {
            ForEach(cardOffsets.indices, id: \.self) { i in
                let o = cardOffsets[i]
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [DS.Colors.bgCard, DS.Colors.bgRaised],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 196)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(DS.Colors.border, lineWidth: 1.5)
                    )
                    .overlay(
                        Text("54")
                            .font(.custom("BarlowCondensed-ExtraBold", size: 40))
                            .foregroundStyle(DS.Colors.gold)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)
                    .offset(
                        x: isShuffling ? o.dx * 2.8 : o.dx,
                        y: o.dy
                    )
                    .rotationEffect(.degrees(isShuffling ? o.rot * 1.6 : o.rot))
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.65)
                        .delay(Double(i) * 0.04),
                        value: isShuffling
                    )
                    .zIndex(Double(i))
            }
        }
        .frame(height: 260)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button {
                coordinator.send(.shuffle)
            } label: {
                Text(isShufflingState ? "SHUFFLING…" : "START")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                    .foregroundStyle(Color(hex: "#111111"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(DS.Colors.gold)
                    .clipShape(Capsule())
                    .shadow(color: DS.Colors.gold.opacity(0.25), radius: 12, x: 0, y: 0)
            }
            .disabled(isShufflingState)

            Button { } label: {
                Text("EQUIPMENT FOR TODAY")
                    .font(.custom("Oswald-SemiBold", size: 13))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .tracking(1.4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 52)
    }
}
