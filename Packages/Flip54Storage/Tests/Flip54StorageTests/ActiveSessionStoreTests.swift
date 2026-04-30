import Foundation
import Testing
import Flip54Core
@testable import Flip54Storage

@Suite("ActiveSessionStore")
struct ActiveSessionStoreTests {

    private func makeStore() -> ActiveSessionStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flip54_test_\(UUID().uuidString).json")
        return ActiveSessionStore(url: url)
    }

    private func makeSession() -> ActiveSession {
        var rng = SystemRandomNumberGenerator()
        return ActiveSession.start(
            deck: Card.standardDeck(),
            deckId: "standard",
            equipment: .bodyWeightOnly,
            difficulty: .standard,
            rng: &rng
        )
    }

    @Test("load returns nil when no file exists")
    func loadNilWhenMissing() {
        let store = makeStore()
        #expect(store.load() == nil)
    }

    @Test("save then load round-trip")
    func saveLoadRoundTrip() throws {
        let store = makeStore()
        let session = makeSession()
        try store.save(session)
        let loaded = store.load()
        #expect(loaded == session)
    }

    @Test("clear removes stored session")
    func clearRemovesSession() throws {
        let store = makeStore()
        let session = makeSession()
        try store.save(session)
        store.clear()
        #expect(store.load() == nil)
    }

    @Test("save overwrites previous session")
    func saveOverwrites() throws {
        let store = makeStore()
        var session = makeSession()
        try store.save(session)
        session.flipNextCard()
        session.completeCurrentCard(reps: 5, holdSeconds: nil)
        try store.save(session)
        let loaded = store.load()
        #expect(loaded?.cardsCompleted == 1)
    }
}
