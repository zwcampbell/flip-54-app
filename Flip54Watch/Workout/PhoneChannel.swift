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

    private func received(_ data: Data) {
        onData?(data)
    }
}

extension PhoneChannel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: (any Error)?) {}

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in self.received(messageData) }
    }
}
