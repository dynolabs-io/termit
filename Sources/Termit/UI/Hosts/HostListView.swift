import SwiftUI

struct HostListView: View {
    @EnvironmentObject var hostStore: HostStore
    @Binding var selection: Host?
    @State private var showEditor = false
    @State private var editing: Host?
    @State private var searchText = ""

    var filteredHosts: [Host] {
        if searchText.isEmpty { return hostStore.hosts }
        let lower = searchText.lowercased()
        return hostStore.hosts.filter {
            $0.alias.lowercased().contains(lower)
                || $0.hostname.lowercased().contains(lower)
                || $0.tags.contains(where: { $0.lowercased().contains(lower) })
        }
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(filteredHosts) { host in
                HostRow(host: host)
                    .tag(host)
                    .swipeActions {
                        Button(role: .destructive) {
                            hostStore.delete(host)
                        } label: { Label("Delete", systemImage: "trash") }
                        Button {
                            editing = host
                            showEditor = true
                        } label: { Label("Edit", systemImage: "pencil") }
                    }
            }
        }
        .searchable(text: $searchText, prompt: "Search hosts and tags")
        .navigationTitle("Termit")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editing = nil
                    showEditor = true
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showEditor) {
            HostEditView(host: editing) { updated in
                if hostStore.hosts.contains(where: { $0.id == updated.id }) {
                    hostStore.update(updated)
                } else {
                    hostStore.add(updated)
                }
                showEditor = false
            }
        }
    }
}

struct HostRow: View {
    let host: Host
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: host.colorHex ?? "#888888"))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(host.alias).font(.headline)
                Text("\(host.username)@\(host.displayHostname)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !host.tags.isEmpty {
                Text(host.tags.first!)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
