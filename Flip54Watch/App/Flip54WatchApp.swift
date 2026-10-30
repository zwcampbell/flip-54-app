import SwiftUI
import Flip54DesignSystem
import Flip54WorkoutEngine

@main
struct Flip54WatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchAppDelegate

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(delegate.model)
        }
    }
}

/// Picks the screen for where the workout is: Start, running, paused or summary.
/// A workout saved on disk is restored by `WatchWorkoutModel` and opens on its
/// face-down card.
struct WatchRootView: View {
    @Environment(WatchWorkoutModel.self) private var model

    var body: some View {
        Group {
            if let summary = model.summary {
                SummaryScreen(summary: summary)
            } else {
                switch model.state {
                case .idle:
                    StartScreen()
                case .paused:
                    NavigationStack { PausedScreen() }
                default:
                    WorkoutScreen()
                }
            }
        }
        // The watch background is pure black, not DS.Colors.bg, so the OLED stays dark.
        .background(Color.black)
        .onChange(of: model.state) { _, new in model.stateChanged(to: new) }
    }
}

#Preview {
    WatchRootView()
        .environment(WatchWorkoutModel(recorder: NoopWorkoutRecorder()))
}
