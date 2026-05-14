import SwiftUI

struct RootView: View {
    @EnvironmentObject var hostStore: HostStore
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedHost: Host?

    var body: some View {
        NavigationSplitView {
            HostListView(selection: $selectedHost)
        } detail: {
            if let host = selectedHost {
                TerminalSessionView(host: host)
                    .id(host.id)
            } else {
                EmptyStateView()
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("Select a host to begin")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}
