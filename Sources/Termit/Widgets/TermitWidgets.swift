import WidgetKit
import SwiftUI

@main
struct TermitWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LastHostWidget()
        StandByWidget()
    }
}

struct LastHostEntry: TimelineEntry {
    let date: Date
    let hostAlias: String?
    let isConnected: Bool
}

struct LastHostProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastHostEntry {
        LastHostEntry(date: Date(), hostAlias: "prod-edge-1", isConnected: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (LastHostEntry) -> Void) {
        let alias = sharedDefaults?.string(forKey: "lastHostAlias")
        completion(LastHostEntry(date: Date(), hostAlias: alias, isConnected: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastHostEntry>) -> Void) {
        let alias = sharedDefaults?.string(forKey: "lastHostAlias")
        let entry = LastHostEntry(date: Date(), hostAlias: alias, isConnected: false)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900))))
    }

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.io.dynolabs.termit")
    }
}

struct LastHostWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LastHostWidget", provider: LastHostProvider()) { entry in
            LastHostWidgetView(entry: entry)
        }
        .configurationDisplayName("Last Host")
        .description("Quickly reconnect to your most recent host.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall, .systemMedium])
    }
}

struct LastHostWidgetView: View {
    let entry: LastHostEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "terminal")
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label(entry.hostAlias ?? "no host", systemImage: "terminal")
                Text(entry.isConnected ? "connected" : "disconnected")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                Label(entry.hostAlias ?? "—", systemImage: "terminal").font(.headline)
                Text(entry.isConnected ? "Connected" : "Not connected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct StandByWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StandByWidget", provider: LastHostProvider()) { entry in
            VStack {
                Image(systemName: "terminal").font(.largeTitle)
                Text(entry.hostAlias ?? "Termit").font(.title2)
            }
        }
        .configurationDisplayName("Termit – StandBy")
        .description("Connection status overnight.")
        .supportedFamilies([.systemSmall])
    }
}
