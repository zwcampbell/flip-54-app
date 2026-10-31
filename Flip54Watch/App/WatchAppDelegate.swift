import WatchKit

/// Owns the workout model so watchOS can hand a still-running Health session
/// back to it after the app is relaunched mid-workout.
@MainActor
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    let model = WatchWorkoutModel()

    func handleActiveWorkoutRecovery() {
        // The deck itself is restored from disk by WatchWorkoutModel's init.
        Task { await model.recorder.recover() }
    }
}
