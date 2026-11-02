import Foundation
import Flip54Storage

/// What the iPhone and watch send each other while the watch follows a
/// workout started on the iPhone. The iPhone runs the deck; the watch shows
/// its snapshots and sends back what the wearer tapped.
public enum RemoteWorkoutMessage: Codable, Equatable, Sendable {
    /// iPhone → watch: the deck as it stands now.
    case snapshot(RemoteWorkoutSnapshot)
    /// iPhone → watch: the workout was ended on the iPhone (or left).
    case ended
    /// Watch → iPhone: something the wearer did on the watch.
    case command(RemoteWorkoutCommand)
    /// Watch → iPhone: a workout run on the watch alone has finished.
    case finished(FinishedWatchWorkout)

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }

    public static func decode(_ data: Data) throws -> RemoteWorkoutMessage {
        try JSONDecoder().decode(RemoteWorkoutMessage.self, from: data)
    }
}

public struct RemoteWorkoutSnapshot: Codable, Equatable, Sendable {
    public let state: WorkoutState
    public let session: ActiveSession?
    public let isHoldPausedInPlace: Bool

    public init(state: WorkoutState, session: ActiveSession?, isHoldPausedInPlace: Bool) {
        self.state = state
        self.session = session
        self.isHoldPausedInPlace = isHoldPausedInPlace
    }
}

public enum RemoteWorkoutCommand: String, Codable, Sendable {
    /// Flip the face-down card.
    case flip
    /// The card's primary action: done, start the hold, or continue after it.
    case done
    /// Skip the card; during a hold, end it early and credit the seconds held.
    case skip
    case pause
    case resume
    /// Tap on the hold timer: pause or resume the hold in place.
    case toggleHoldPause
    /// End the workout (already confirmed on the watch).
    case end
}

extension WorkoutCoordinator {
    public var remoteSnapshot: RemoteWorkoutSnapshot {
        RemoteWorkoutSnapshot(state: state, session: session, isHoldPausedInPlace: isHoldPausedInPlace)
    }
}

/// A workout started and finished on the watch, sent to the iPhone so it
/// lands in History. `id` becomes the History entry's id, so a record
/// delivered twice is saved once.
public struct FinishedWatchWorkout: Codable, Equatable, Sendable {
    /// The WatchConnectivity user-info key the record travels under.
    public static let userInfoKey = "flip54.finishedWatchWorkout"

    public let id: UUID
    public let session: ActiveSession
    public let completedAt: Date

    public init(id: UUID = UUID(), session: ActiveSession, completedAt: Date) {
        self.id = id
        self.session = session
        self.completedAt = completedAt
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }

    public static func decode(_ data: Data) throws -> FinishedWatchWorkout {
        try JSONDecoder().decode(FinishedWatchWorkout.self, from: data)
    }
}
