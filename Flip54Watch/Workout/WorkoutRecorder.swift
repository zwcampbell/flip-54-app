import Foundation
import HealthKit
import Observation
import os

private let log = Logger(subsystem: "com.flip54.app.watchkitapp", category: "WorkoutRecorder")

/// Where saving the finished workout to Apple Health stands.
enum HealthSaveState: Equatable {
    case idle
    case saving
    case saved
    case failed
    /// Health access was denied or the session couldn't start; the workout ran without it.
    case unavailable
}

/// What the deck adds to the saved workout's metadata.
struct WorkoutTotals: Sendable {
    let reps: Int
    let cards: Int
    let deckSize: Int
}

/// Records a workout to Apple Health alongside the deck. Kept behind a protocol
/// so the workout model doesn't depend on HealthKit and previews never prompt.
@MainActor
protocol WorkoutRecorder: AnyObject {
    /// Latest heart rate in bpm, nil until the first sample.
    var heartRate: Double? { get }
    var averageHeartRate: Double? { get }
    /// Active energy so far, in kcal.
    var activeCalories: Double { get }
    var saveState: HealthSaveState { get }
    /// Called when watchOS pauses or resumes the session itself (true = paused).
    var onExternalPauseChange: ((Bool) -> Void)? { get set }

    func start(at date: Date) async
    func pause()
    func resume()
    /// Ends the session and saves the workout to Health, or discards it.
    func finish(at date: Date, save: Bool, totals: WorkoutTotals) async
    /// Reattaches to a session that survived the app being relaunched.
    func recover() async
}

/// Runs an `HKWorkoutSession` with a live builder: keeps the app running with
/// the wrist down, streams heart rate and calories, and saves the workout.
@MainActor
@Observable
final class HealthKitWorkoutRecorder: NSObject, WorkoutRecorder {
    private(set) var heartRate: Double?
    private(set) var averageHeartRate: Double?
    private(set) var activeCalories: Double = 0
    private(set) var saveState: HealthSaveState = .idle
    @ObservationIgnored var onExternalPauseChange: ((Bool) -> Void)?

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    /// True while we're the ones pausing/resuming, so the delegate doesn't echo it back.
    @ObservationIgnored private var changingPauseOurselves = false

    private static let heartRateType = HKQuantityType(.heartRate)
    private static let energyType = HKQuantityType(.activeEnergyBurned)
    private static let bpm = HKUnit.count().unitDivided(by: .minute())

    func start(at date: Date) async {
        resetStats()
        guard HKHealthStore.isHealthDataAvailable() else {
            saveState = .unavailable
            return
        }
        do {
            try await store.requestAuthorization(
                toShare: [HKObjectType.workoutType()],
                read: [Self.heartRateType, Self.energyType]
            )
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .functionalStrengthTraining
            configuration.locationType = .indoor
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            attach(session: session, builder: builder)
            session.startActivity(with: date)
            try await builder.beginCollection(at: date)
            log.info("Workout session started")
        } catch {
            // Never block the workout on Health: carry on without a session.
            log.error("Couldn't start workout session: \(error.localizedDescription, privacy: .public)")
            detach()
            saveState = .unavailable
        }
    }

    func pause() {
        changingPauseOurselves = true
        session?.pause()
    }

    func resume() {
        changingPauseOurselves = true
        session?.resume()
    }

    func finish(at date: Date, save: Bool, totals: WorkoutTotals) async {
        guard let session, let builder else {
            // No session (Health denied, or a deck restored without one): nothing to save.
            if save { saveState = .unavailable }
            return
        }
        session.end()
        do {
            try await builder.endCollection(at: date)
            if save {
                saveState = .saving
                try await builder.addMetadata([
                    HKMetadataKeyIndoorWorkout: true,
                    "Flip54Reps": totals.reps,
                    "Flip54Cards": totals.cards,
                    "Flip54DeckSize": totals.deckSize,
                ])
                let workout = try await builder.finishWorkout()
                saveState = .saved
                log.info("Saved workout: \(workout?.duration ?? 0, privacy: .public)s, metadata \(String(describing: workout?.metadata), privacy: .public)")
            } else {
                builder.discardWorkout()
                saveState = .idle
                log.info("Discarded workout with no cards done")
            }
        } catch {
            log.error("Couldn't finish workout: \(error.localizedDescription, privacy: .public)")
            saveState = save ? .failed : .idle
        }
        detach()
    }

    func recover() async {
        do {
            let session = try await store.recoverActiveWorkoutSession()
            guard let session else { return }
            attach(session: session, builder: session.associatedWorkoutBuilder())
            log.info("Recovered workout session")
        } catch {
            log.error("Couldn't recover workout session: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Helpers

    private func attach(session: HKWorkoutSession, builder: HKLiveWorkoutBuilder) {
        self.session = session
        self.builder = builder
        session.delegate = self
        builder.delegate = self
    }

    private func detach() {
        session = nil
        builder = nil
    }

    private func resetStats() {
        heartRate = nil
        averageHeartRate = nil
        activeCalories = 0
        saveState = .idle
    }

    private func readStatistics(from builder: HKLiveWorkoutBuilder) {
        if let stats = builder.statistics(for: Self.heartRateType) {
            heartRate = stats.mostRecentQuantity()?.doubleValue(for: Self.bpm)
            averageHeartRate = stats.averageQuantity()?.doubleValue(for: Self.bpm)
        }
        if let stats = builder.statistics(for: Self.energyType) {
            activeCalories = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        }
    }

    private func sessionChanged(to state: HKWorkoutSessionState, from old: HKWorkoutSessionState) {
        defer { changingPauseOurselves = false }
        guard !changingPauseOurselves else { return }
        if state == .paused, old == .running {
            onExternalPauseChange?(true)
        } else if state == .running, old == .paused {
            onExternalPauseChange?(false)
        }
    }
}

extension HealthKitWorkoutRecorder: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        Task { @MainActor in self.sessionChanged(to: toState, from: fromState) }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        log.error("Workout session failed: \(error.localizedDescription, privacy: .public)")
    }
}

extension HealthKitWorkoutRecorder: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in self.readStatistics(from: workoutBuilder) }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

/// Stand-in for previews: records nothing and never prompts.
@MainActor
final class NoopWorkoutRecorder: WorkoutRecorder {
    var heartRate: Double? = 128
    var averageHeartRate: Double? = 131
    var activeCalories: Double = 142
    var saveState: HealthSaveState = .saved
    var onExternalPauseChange: ((Bool) -> Void)?

    func start(at date: Date) async {}
    func pause() {}
    func resume() {}
    func finish(at date: Date, save: Bool, totals: WorkoutTotals) async {}
    func recover() async {}
}
