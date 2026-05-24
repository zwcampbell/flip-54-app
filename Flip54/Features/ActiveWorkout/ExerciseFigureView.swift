import SwiftUI
import Flip54Core

struct ExerciseFigureView: View {
    let exercise: Exercise

    @State private var frameIndex = 0
    private let timer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()

    /// All available frame asset names for this exercise (_a, _b, _c, _d).
    /// Most exercises have 2 frames; burpee has 4.
    private var frameNames: [String] {
        ["_a", "_b", "_c", "_d"]
            .map { "form_\(exercise.rawValue)\($0)" }
            .filter { UIImage(named: $0) != nil }
    }

    var body: some View {
        if frameNames.isEmpty {
            placeholder
        } else {
            ZStack {
                Image(frameNames[frameIndex])
                    .resizable()
                    .scaledToFit()
                    // .id forces SwiftUI to treat each frame as a new view,
                    // enabling the opacity cross-fade transition.
                    .id(frameIndex)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.4), value: frameIndex)
            .onReceive(timer) { _ in
                frameIndex = (frameIndex + 1) % frameNames.count
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(DS.Colors.textTertiary.opacity(0.4))
            Text("DEMO FIGURE")
                .font(.custom("IBMPlexMono-Medium", size: 10))
                .foregroundStyle(DS.Colors.textTertiary.opacity(0.5))
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
