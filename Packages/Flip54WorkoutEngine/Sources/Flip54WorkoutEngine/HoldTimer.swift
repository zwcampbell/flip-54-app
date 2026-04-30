import Foundation

/// Manages the countdown timer for Ace hold exercises.
/// Fires `onExpired` when the hold duration elapses.
/// Supports pause/resume with accurate remaining time tracking.
@MainActor
public final class HoldTimer {
    private var timer: Timer?
    private var fireDate: Date?
    public private(set) var remainingSeconds: Int = 0

    public var onExpired: (() -> Void)?
    public var onTick: ((Int) -> Void)?

    public init() {}

    public func start(durationSeconds: Int, alreadyElapsed: TimeInterval = 0) {
        cancel()
        let remaining = max(0, Double(durationSeconds) - alreadyElapsed)
        remainingSeconds = Int(remaining.rounded(.up))
        fireDate = Date().addingTimeInterval(remaining)
        scheduleTimer(interval: remaining)
    }

    public func pause() -> TimeInterval {
        guard let fire = fireDate else { return 0 }
        cancel()
        let remaining = max(0, fire.timeIntervalSince(Date()))
        remainingSeconds = Int(remaining.rounded(.up))
        return remaining
    }

    public func resume(remainingSeconds: Int) {
        cancel()
        let interval = Double(remainingSeconds)
        fireDate = Date().addingTimeInterval(interval)
        self.remainingSeconds = remainingSeconds
        scheduleTimer(interval: interval)
    }

    public func cancel() {
        timer?.invalidate()
        timer = nil
        fireDate = nil
    }

    private func scheduleTimer(interval: TimeInterval) {
        let t = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.remainingSeconds = 0
                self?.onExpired?()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t

        // Secondary per-second tick timer for UI countdown
        let tickTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let fire = self.fireDate else { return }
                let remaining = max(0, Int(fire.timeIntervalSince(Date()).rounded(.up)))
                self.remainingSeconds = remaining
                self.onTick?(remaining)
            }
        }
        RunLoop.main.add(tickTimer, forMode: .common)
    }
}
