import ActivityKit
import SwiftUI
import WidgetKit

struct TermitSessionActivityAttributes: ActivityAttributes {
    public typealias ContentState = SessionState

    public struct SessionState: Codable, Hashable {
        public var hostAlias: String
        public var status: String
        public var rxBytes: Int
        public var txBytes: Int
        public init(hostAlias: String, status: String, rxBytes: Int = 0, txBytes: Int = 0) {
            self.hostAlias = hostAlias
            self.status = status
            self.rxBytes = rxBytes
            self.txBytes = txBytes
        }
    }

    public let sessionID: String
    public init(sessionID: String) { self.sessionID = sessionID }
}

struct TermitSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TermitSessionActivityAttributes.self) { context in
            HStack {
                Image(systemName: "terminal")
                VStack(alignment: .leading) {
                    Text(context.state.hostAlias).font(.headline)
                    Text(context.state.status).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("↓\(context.state.rxBytes)  ↑\(context.state.txBytes)")
                    .font(.caption.monospacedDigit())
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.hostAlias, systemImage: "terminal")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("↓ \(context.state.rxBytes)B  ↑ \(context.state.txBytes)B")
                        .font(.caption.monospacedDigit())
                }
            } compactLeading: {
                Image(systemName: "terminal")
            } compactTrailing: {
                Text(context.state.hostAlias).font(.caption2)
            } minimal: {
                Image(systemName: "terminal")
            }
        }
    }
}
