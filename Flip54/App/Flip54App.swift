import SwiftUI

@main
struct Flip54App: App {
    var body: some Scene {
        WindowGroup {
            Text("Flip 54")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#111111"))
        }
    }
}
