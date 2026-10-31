import SwiftUI
import WidgetKit
import Flip54DesignSystem

@main
struct Flip54WatchWidgets: WidgetBundle {
    var body: some Widget {
        Flip54PlaceholderComplication()
    }
}

// Placeholder so the extension builds and installs in step 1. Replaced by the
// circular, rectangular, corner and Smart Stack widgets in step 8.

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
    }
}

struct Flip54PlaceholderComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Flip54Placeholder", provider: PlaceholderProvider()) { _ in
            DS.Typography.display("54", size: 22)
                .foregroundStyle(DS.Colors.gold)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Flip 54")
        .description("Start a Flip 54 workout.")
        .supportedFamilies([.accessoryCircular])
    }
}
