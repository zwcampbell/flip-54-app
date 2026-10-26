import SwiftUI
import Flip54DesignSystem

@main
struct Flip54WatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}

/// Placeholder root for build step 1 (targets, packages and fonts compile).
/// Replaced by the Start screen in step 3.
struct WatchRootView: View {
    var body: some View {
        VStack(spacing: 4) {
            DS.Typography.display("FLIP 54", size: 34)
                .foregroundStyle(DS.Colors.gold)
            DS.Typography.sub("APPLE WATCH", size: 12)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The watch background is pure black, not DS.Colors.bg, so the OLED stays dark.
        .background(Color.black)
    }
}

#Preview {
    WatchRootView()
}
