import Foundation
import SwiftData

public extension ModelContainer {
    static func flip54Container(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            WorkoutHistory.self,
            UserSettings.self,
            DeckInventory.self,
            OnboardingState.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: .identifier("group.com.flip54.app")
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
