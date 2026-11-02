import SwiftUI
import SwiftData
import Flip54Storage

@main
struct Flip54App: App {
    private let container: ModelContainer = {
        do {
            return try ModelContainer.flip54Container()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// Made at launch, not with the first screen, so a workout the watch
    /// queued for History is saved even when the app wakes in the background.
    @State private var watchLink: WatchWorkoutLink

    init() {
        _watchLink = State(initialValue: WatchWorkoutLink(container: container))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(watchLink)
        }
        .modelContainer(container)
    }
}
