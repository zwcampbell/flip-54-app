import Foundation
import Testing
import SwiftData
import Flip54Core
@testable import Flip54Storage

@Suite("SwiftData Models")
struct SwiftDataModelTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer.flip54Container(inMemory: true)
    }

    @Test("WorkoutHistory insert and fetch")
    func workoutHistoryInsertFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let history = WorkoutHistory(
            completedAt: Date(),
            duration: 1200,
            deckId: "standard",
            difficulty: .standard,
            totalReps: 250,
            holdSecondsCompleted: 120,
            cardCount: 54,
            skipCount: 2,
            repsBySuit: [.hearts: 60, .spades: 55, .clubs: 70, .diamonds: 65],
            jumpingJacks: 40
        )
        context.insert(history)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkoutHistory>())
        #expect(fetched.count == 1)
        #expect(fetched[0].totalReps == 250)
        #expect(fetched[0].repsBySuit[.hearts] == 60)
        #expect(fetched[0].difficulty == .standard)
    }

    @Test("UserSettings insert and fetch")
    func userSettingsInsertFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let settings = UserSettings(
            hasWeights: true,
            hasPullUpBar: true,
            difficulty: .advanced
        )
        context.insert(settings)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserSettings>())
        #expect(fetched.count == 1)
        #expect(fetched[0].hasWeights == true)
        #expect(fetched[0].difficulty == .advanced)
        #expect(fetched[0].equipment.hasPullUpBar == true)
    }

    @Test("DeckInventory insert and fetch")
    func deckInventoryInsertFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let standard = DeckInventory(deckId: "standard", unlockedAt: Date(), equipped: true)
        let shiny = DeckInventory(deckId: "shiny", unlockedAt: nil, equipped: false)
        context.insert(standard)
        context.insert(shiny)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DeckInventory>())
        #expect(fetched.count == 2)
        let standardFetched = fetched.first { $0.deckId == "standard" }
        #expect(standardFetched?.isUnlocked == true)
        #expect(standardFetched?.equipped == true)
        let shinyFetched = fetched.first { $0.deckId == "shiny" }
        #expect(shinyFetched?.isUnlocked == false)
    }

    @Test("OnboardingState insert and resetTooltips")
    func onboardingStateInsertReset() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let state = OnboardingState(
            hasSeenWelcome: true,
            seenAceTooltip: true,
            seenJokerTooltip: true
        )
        context.insert(state)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<OnboardingState>())
        #expect(fetched.count == 1)
        #expect(fetched[0].hasSeenWelcome == true)
        #expect(fetched[0].seenAceTooltip == true)

        fetched[0].resetTooltips()
        #expect(fetched[0].seenAceTooltip == false)
        #expect(fetched[0].seenJokerTooltip == false)
    }

    @Test("WorkoutHistory repsBySuit computed property")
    func workoutHistoryRepsBySuit() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let history = WorkoutHistory(
            completedAt: Date(),
            duration: 900,
            deckId: "standard",
            difficulty: .beginner,
            totalReps: 100,
            holdSecondsCompleted: 45,
            cardCount: 54,
            skipCount: 0,
            repsBySuit: [.hearts: 25, .spades: 20, .clubs: 30, .diamonds: 25],
            jumpingJacks: 30
        )
        context.insert(history)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkoutHistory>())[0]
        #expect(fetched.repsBySuit[.hearts] == 25)
        #expect(fetched.repsBySuit[.spades] == 20)
        #expect(fetched.repsBySuit[.clubs] == 30)
        #expect(fetched.repsBySuit[.diamonds] == 25)
    }
}
