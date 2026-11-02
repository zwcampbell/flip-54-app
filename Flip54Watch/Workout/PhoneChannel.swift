import Foundation
import WatchConnectivity
import os
import Flip54WorkoutEngine

private let log = Logger(subsystem: "com.flip54.app.watchkitapp", category: "PhoneChannel")

/// The watch's side of the WatchConnectivity link to the iPhone. Used to
/// exchange `RemoteWorkoutMessage`s while following a workout started on the
/// iPhone, alongside the mirrored Health session (which needs the real
/// device link and isn't available in the simulator).
@MainActor
final class PhoneChannel: NSObject {
    /// Called with each message the iPhone sends.
    var onData: ((Data) -> Void)?
    /// Called with the iPhone's workout setup and deck unlocks.
    var onSettings: ((SyncedSettings) -> Void)?
    /// Settings waiting for WatchConnectivity to finish activating.
    private var pendingSettings: SyncedSettings?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// True when a message sent now will reach the iPhone app.
    var isReachable: Bool {
        WCSession.isSupported()
            && WCSession.default.activationState == .activated
            && WCSession.default.isReachable
    }

    func send(_ data: Data) {
        WCSession.default.sendMessageData(data, replyHandler: nil) { error in
            log.error("Couldn't message the iPhone: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Sends a finished watch workout to the iPhone's History: straight away
    /// when the iPhone app can hear it, and also queued, which WatchConnectivity
    /// keeps until the iPhone app can take it, even across relaunches. The
    /// iPhone saves each workout once, however many copies arrive.
    func sendFinished(_ workout: FinishedWatchWorkout) {
        guard WCSession.isSupported(), let data = try? workout.encoded() else { return }
        guard WCSession.default.activationState == .activated else {
            log.error("Not sending the finished workout: WatchConnectivity isn't active")
            return
        }
        if isReachable, let message = try? RemoteWorkoutMessage.finished(workout).encoded() {
            send(message)
        }
        WCSession.default.transferUserInfo([FinishedWatchWorkout.userInfoKey: data])
        log.info("Queued a finished workout for the iPhone: \(workout.session.cardsCompleted, privacy: .public) cards")
    }

    /// Shares the watch's setup with the iPhone. Only the latest matters, so
    /// it goes as the application context, which replaces any unsent one.
    func sendSettings(_ settings: SyncedSettings) {
        guard WCSession.isSupported() else { return }
        guard WCSession.default.activationState == .activated else {
            pendingSettings = settings
            return
        }
        do {
            try WCSession.default.updateApplicationContext([SyncedSettings.contextKey: settings.encoded()])
        } catch {
            log.error("Couldn't share settings with the iPhone: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func received(_ data: Data) {
        onData?(data)
    }

    private func receivedContext(_ context: [String: Any]) {
        guard let data = context[SyncedSettings.contextKey] as? Data,
              let settings = try? SyncedSettings.decode(data) else { return }
        onSettings?(settings)
    }

    private func activated(latestContext: [String: Any]) {
        receivedContext(latestContext)
        if let pendingSettings {
            self.pendingSettings = nil
            sendSettings(pendingSettings)
        }
    }
}

extension PhoneChannel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: (any Error)?) {
        guard activationState == .activated else { return }
        // The iPhone's latest settings, which may have arrived while the app was closed.
        let data = session.receivedApplicationContext[SyncedSettings.contextKey] as? Data
        Task { @MainActor in self.activated(latestContext: data.map { [SyncedSettings.contextKey: $0] } ?? [:]) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext[SyncedSettings.contextKey] as? Data
        Task { @MainActor in self.receivedContext(data.map { [SyncedSettings.contextKey: $0] } ?? [:]) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in self.received(messageData) }
    }
}
