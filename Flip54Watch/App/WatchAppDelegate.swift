import HealthKit
import WatchKit

/// Owns the workout model so watchOS can hand a still-running Health session
/// back to it after the app is relaunched mid-workout, and so the iPhone can
/// launch the app into a workout it started.
@MainActor
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    let model = WatchWorkoutModel()

    func handleActiveWorkoutRecovery() {
        // The deck itself is restored from disk by WatchWorkoutModel's init.
        Task { await model.recorder.recover() }
    }

    /// The iPhone started a workout (`HKHealthStore.startWatchApp(with:)`).
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        model.startFollowingPhone()
    }
}
