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
                case .idle where model.isFollowingPhone:
                    FollowingPhoneScreen()
                case .idle:
                    StartScreen()
                case .paused where !model.isHoldPausedByTap:
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

/// Shown for the moment between the iPhone launching the watch app and its
/// first snapshot of the deck arriving.
struct FollowingPhoneScreen: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone")
                .font(.system(size: 30))
                .foregroundStyle(DS.Colors.gold)
            Text("STARTING ON IPHONE")
                .font(WatchType.sub(13)).tracking(1)
                .foregroundStyle(DS.Colors.textSecondary)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WatchRootView()
        .environment(WatchWorkoutModel(recorder: NoopWorkoutRecorder()))
}
