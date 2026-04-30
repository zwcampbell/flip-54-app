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
        // App Group is used on-device for Watch-readiness.
        // Simulator and in-memory builds use the default container location.
        #if targetEnvironment(simulator)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        #else
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier("group.com.flip54.app")
        )
        #endif
        return try ModelContainer(for: schema, configurations: [config])
    }
}
