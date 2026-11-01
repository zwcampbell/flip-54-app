import Foundation
import WatchConnectivity
import os

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
