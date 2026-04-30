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

    var body: some Scene {
        WindowGroup {
            Text("Flip 54")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#111111"))
        }
        .modelContainer(container)
    }
}
