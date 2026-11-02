import Foundation
import Testing
import Flip54Core
@testable import Flip54WorkoutEngine

@Suite("SyncedSettings — merging the other device's setup")
struct SyncedSettingsTests {
    private let earlier = Date(timeIntervalSince1970: 1_800_000_000)
    private let later = Date(timeIntervalSince1970: 1_800_000_100)

    @Test("newer choices from the other device win; older ones are ignored")
    func newerChoicesWin() {
        let watch = SyncedSettings(difficulty: .beginner, changedAt: earlier)
        let phone = SyncedSettings(difficulty: .advanced, hasWeights: true, changedAt: later)
        let merged = watch.merged(withRemote: phone, remoteIsPhone: true)
        #expect(merged.difficulty == .advanced)
        #expect(merged.hasWeights)
        #expect(merged.changedAt == later)

        let stale = phone.merged(withRemote: watch, remoteIsPhone: false)
        #expect(stale.difficulty == .advanced)
    }

    @Test("unlocks come only from the iPhone, even with older choices")
    func unlocksFromPhoneOnly() {
        let watch = SyncedSettings(unlockedDeckIds: ["standard"], changedAt: later)
        let phone = SyncedSettings(unlockedDeckIds: ["standard", "midas"], workoutsToUnlock: [:], changedAt: earlier)
        #expect(watch.merged(withRemote: phone, remoteIsPhone: true).unlockedDeckIds.contains("midas"))

        let fromWatch = SyncedSettings(unlockedDeckIds: ["standard", "midas"], changedAt: later)
        let phoneLocked = SyncedSettings(unlockedDeckIds: ["standard"], workoutsToUnlock: ["midas": 4], changedAt: earlier)
        #expect(!phoneLocked.merged(withRemote: fromWatch, remoteIsPhone: false).unlockedDeckIds.contains("midas"))
    }

    @Test("a card style that isn't unlocked falls back to the standard deck")
    func lockedStyleFallsBack() {
        let watch = SyncedSettings(deckId: "midas", unlockedDeckIds: ["standard", "midas"], changedAt: later)
        let phone = SyncedSettings(unlockedDeckIds: ["standard"], changedAt: earlier)
        #expect(watch.merged(withRemote: phone, remoteIsPhone: true).deckId == "standard")
    }

    @Test("settings survive encoding")
    func roundTrip() throws {
        let settings = SyncedSettings(difficulty: .advanced, useHalfDeck: true, deckId: "midas",
                                      disabledExercises: [.burpee], unlockedDeckIds: ["standard", "midas"],
                                      workoutsToUnlock: ["masonic": 3], changedAt: later)
        #expect(try SyncedSettings.decode(settings.encoded()) == settings)
    }
}
