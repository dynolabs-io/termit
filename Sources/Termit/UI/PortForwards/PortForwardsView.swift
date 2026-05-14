import SwiftUI

struct PortForwardsView: View {
    let host: Host
    @State private var forwards: [PortForward] = []
    @State private var showEditor = false
    @State private var editing: PortForward?

    var body: some View {
        List {
            ForEach(forwards) { f in
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(f.kind.rawValue.uppercased()) :\(f.localPort)\(f.remoteHost.map { " → \($0):\(f.remotePort ?? 0)" } ?? "")", systemImage: "arrow.left.arrow.right")
                        .font(.headline)
                    if !f.description.isEmpty {
                        Text(f.description).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        forwards.removeAll { $0.id == f.id }
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
        .navigationTitle("Port Forwards")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editing = nil; showEditor = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showEditor) {
            PortForwardEditView(existing: editing) { f in
                if let idx = forwards.firstIndex(where: { $0.id == f.id }) {
                    forwards[idx] = f
                } else {
                    forwards.append(f)
                }
                showEditor = false
            }
        }
    }
}

struct PortForwardEditView: View {
    let existing: PortForward?
    let onSave: (PortForward) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var kind: PortForward.Kind = .local
    @State private var localPort: Int = 8080
    @State private var remoteHost: String = ""
    @State private var remotePort: Int = 80
    @State private var description: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Kind", selection: $kind) {
                    Text("Local (-L)").tag(PortForward.Kind.local)
                    Text("Remote (-R)").tag(PortForward.Kind.remote)
                    Text("Dynamic SOCKS (-D)").tag(PortForward.Kind.socks)
                }
                TextField("Local port", value: $localPort, format: .number)
                if kind != .socks {
                    TextField("Remote host", text: $remoteHost)
                        .textInputAutocapitalization(.never)
                    TextField("Remote port", value: $remotePort, format: .number)
                }
                TextField("Description (optional)", text: $description)
            }
            .navigationTitle(existing == nil ? "New Forward" : "Edit Forward")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(PortForward(
                            id: existing?.id ?? UUID(),
                            kind: kind,
                            localPort: localPort,
                            remoteHost: kind == .socks ? nil : remoteHost,
                            remotePort: kind == .socks ? nil : remotePort,
                            description: description
                        ))
                    }
                }
            }
            .onAppear {
                guard let e = existing else { return }
                kind = e.kind
                localPort = e.localPort
                remoteHost = e.remoteHost ?? ""
                remotePort = e.remotePort ?? 80
                description = e.description
            }
        }
    }
}
