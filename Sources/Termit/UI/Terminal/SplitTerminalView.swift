import SwiftUI

struct SplitTerminalView: View {
    @Binding var openSessions: [Host]
    @Binding var selectedSession: Host?
    @State private var splitOrientation: SplitOrientation = .none

    enum SplitOrientation: String, CaseIterable {
        case none, horizontal, vertical
    }

    var body: some View {
        VStack(spacing: 0) {
            SessionTabBar(openSessions: $openSessions, selectedSession: $selectedSession)
            switch splitOrientation {
            case .none:
                if let host = selectedSession {
                    TerminalSessionView(host: host).id(host.id)
                } else {
                    EmptyStateView()
                }
            case .horizontal:
                HStack(spacing: 1) {
                    paneA
                    Divider()
                    paneB
                }
            case .vertical:
                VStack(spacing: 1) {
                    paneA
                    Divider()
                    paneB
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Picker("Split", selection: $splitOrientation) {
                    ForEach(SplitOrientation.allCases, id: \.self) { o in
                        Text(o.rawValue.capitalized).tag(o)
                    }
                }
            }
        }
    }

    private var paneA: some View {
        Group {
            if let host = openSessions.first {
                TerminalSessionView(host: host).id(host.id)
            } else {
                EmptyStateView()
            }
        }
    }

    private var paneB: some View {
        Group {
            if openSessions.count > 1 {
                TerminalSessionView(host: openSessions[1]).id(openSessions[1].id)
            } else {
                EmptyStateView()
            }
        }
    }
}
