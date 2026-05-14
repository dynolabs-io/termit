import SwiftUI

struct SFTPBrowserView: View {
    let host: Host
    @State private var entries: [SFTPEntry] = []
    @State private var currentPath = "."
    @State private var loading = false
    @State private var error: String?
    @State private var client: SFTPClient?

    var body: some View {
        List(entries) { entry in
            HStack {
                Image(systemName: entry.isDirectory ? "folder.fill" : "doc.text")
                    .foregroundStyle(entry.isDirectory ? Color.accentColor : .secondary)
                VStack(alignment: .leading) {
                    Text(entry.name)
                    Text("\(entry.size) bytes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if entry.isDirectory {
                    currentPath = currentPath == "." ? entry.name : "\(currentPath)/\(entry.name)"
                    refresh()
                }
            }
        }
        .navigationTitle(currentPath)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { Button("Refresh") { refresh() } }
        }
        .onAppear { connectAndList() }
        .overlay {
            if loading { ProgressView() }
            if let error = error {
                Text(error).foregroundStyle(.red).padding()
            }
        }
    }

    private func connectAndList() {
        Task {
            let c = SFTPClient(host: host)
            do {
                try await c.connect()
                self.client = c
                refresh()
            } catch {
                self.error = String(describing: error)
            }
        }
    }

    private func refresh() {
        guard let c = client else { return }
        loading = true
        Task {
            do {
                let list = try await c.list(currentPath)
                self.entries = list.sorted { $0.name < $1.name }
            } catch {
                self.error = String(describing: error)
            }
            loading = false
        }
    }
}
