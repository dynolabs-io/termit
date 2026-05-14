import SwiftUI

struct SessionTabBar: View {
    @Binding var openSessions: [Host]
    @Binding var selectedSession: Host?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(openSessions, id: \.id) { host in
                    Button {
                        selectedSession = host
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "terminal")
                            Text(host.alias)
                            Button {
                                close(host)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedSession?.id == host.id ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(.thinMaterial)
    }

    private func close(_ host: Host) {
        openSessions.removeAll { $0.id == host.id }
        if selectedSession?.id == host.id { selectedSession = openSessions.first }
    }
}
