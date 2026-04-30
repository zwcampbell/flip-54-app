import Foundation
import Flip54Core

public final class ActiveSessionStore: Sendable {
    private let url: URL

    public init(url: URL? = nil) {
        if let url {
            self.url = url
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = support.appendingPathComponent("Flip54", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.url = dir.appendingPathComponent("active_session.json")
        }
    }

    public func save(_ session: ActiveSession) throws {
        let data = try JSONEncoder().encode(session)
        try data.write(to: url, options: .atomic)
    }

    public func load() -> ActiveSession? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ActiveSession.self, from: data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
