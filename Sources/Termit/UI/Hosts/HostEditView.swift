import SwiftUI

struct HostEditView: View {
    let host: Host?
    let onSave: (Host) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var alias = ""
    @State private var hostname = ""
    @State private var port = 22
    @State private var username = ""
    @State private var auth: Host.Auth = .publicKey
    @State private var password = ""
    @State private var tagsRaw = ""
    @State private var moshPreference: Host.MoshPreference = .auto
    @State private var notes = ""
    @State private var enclaveKeys: [EnclaveKey] = []
    @State private var selectedKey: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Alias", text: $alias)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("Hostname or IP", text: $hostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("Port", value: $port, format: .number)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                Section("Authentication") {
                    Picker("Method", selection: $auth) {
                        Text("Public Key (Secure Enclave)").tag(Host.Auth.publicKey)
                        Text("Password").tag(Host.Auth.password)
                        Text("Agent").tag(Host.Auth.agent)
                    }
                    if auth == .password {
                        SecureField("Password", text: $password)
                    }
                    if auth == .publicKey {
                        Picker("Key", selection: $selectedKey) {
                            Text("No key selected").tag(String?.none)
                            ForEach(enclaveKeys, id: \.id) { k in
                                Text(k.label).tag(Optional(k.id))
                            }
                        }
                        Button("Generate new Secure Enclave key") {
                            generateKey()
                        }
                    }
                }
                Section("Mosh") {
                    Picker("Preference", selection: $moshPreference) {
                        Text("Auto (Mosh if available)").tag(Host.MoshPreference.auto)
                        Text("Always SSH").tag(Host.MoshPreference.forceSSH)
                        Text("Require Mosh").tag(Host.MoshPreference.requireMosh)
                    }
                }
                Section("Tags") {
                    TextField("comma-separated", text: $tagsRaw)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle(host == nil ? "New Host" : "Edit Host")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(alias.isEmpty || hostname.isEmpty || username.isEmpty) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        enclaveKeys = EnclaveKeyManager.shared.listAll()
        guard let host = host else { return }
        alias = host.alias
        hostname = host.hostname
        port = host.port
        username = host.username
        auth = host.auth
        tagsRaw = host.tags.joined(separator: ", ")
        moshPreference = host.moshPreference
        notes = host.notes
        selectedKey = host.keychainKeyID
    }

    private func generateKey() {
        do {
            let key = try EnclaveKeyManager.shared.generate(label: "Termit – \(alias.isEmpty ? "key" : alias)")
            enclaveKeys.append(key)
            selectedKey = key.id
        } catch {
            // surface to UI in production code
        }
    }

    private func save() {
        let tags = tagsRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let updated = Host(
            id: host?.id ?? UUID(),
            alias: alias,
            hostname: hostname,
            port: port,
            username: username,
            auth: auth,
            keychainKeyID: selectedKey,
            tags: tags,
            moshPreference: moshPreference,
            moshInstallChoice: host?.moshInstallChoice ?? .unset,
            moshUDPPortRange: host?.moshUDPPortRange ?? 60000...61000,
            colorHex: host?.colorHex,
            notes: notes,
            lastConnected: host?.lastConnected
        )
        if auth == .password && !password.isEmpty {
            try? CredentialStore.shared.storePassword(password, for: updated)
        }
        onSave(updated)
    }
}
