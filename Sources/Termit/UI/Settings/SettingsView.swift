import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeStore: ThemeStore
    @State private var iCloudSync = Preferences.shared.iCloudSyncEnabled
    @State private var biometricEverySession = Preferences.shared.biometricRequiredEverySession
    @State private var fontSize = Preferences.shared.fontSize

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeStore.selectedID) {
                    ForEach(themeStore.themes) { t in
                        Text(t.name).tag(t.id)
                    }
                }
                Stepper(value: $fontSize, in: 9...22) {
                    Text("Font size: \(Int(fontSize)) pt")
                }
                .onChange(of: fontSize) { _, new in Preferences.shared.fontSize = new }
            }
            Section("Security") {
                Toggle("Biometric every session", isOn: $biometricEverySession)
                    .onChange(of: biometricEverySession) { _, v in Preferences.shared.biometricRequiredEverySession = v }
                NavigationLink("Manage Secure Enclave keys", destination: EnclaveKeysListView())
            }
            Section("Sync") {
                Toggle("iCloud sync (encrypted)", isOn: $iCloudSync)
                    .onChange(of: iCloudSync) { _, v in Preferences.shared.iCloudSyncEnabled = v }
                Text("Hosts and snippets sync end-to-end encrypted. Keys never leave your device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("About") {
                LabeledContent("Version", value: appVersion)
                Link("Source on GitHub", destination: URL(string: "https://github.com/dynolabs-io/termit")!)
                Link("Mosh upstream (GPL v3)", destination: URL(string: "https://github.com/mobile-shell/mosh")!)
                Link("Third-party licenses", destination: URL(string: "https://github.com/dynolabs-io/termit/blob/main/THIRD_PARTY_LICENSES.md")!)
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0"
    }
}

struct EnclaveKeysListView: View {
    @State private var keys: [EnclaveKey] = []

    var body: some View {
        List {
            ForEach(keys) { k in
                VStack(alignment: .leading, spacing: 4) {
                    Text(k.label).font(.headline)
                    Text(k.algorithm.rawValue).font(.caption).foregroundStyle(.secondary)
                    Text(k.publicKeySHA256).font(.caption2).foregroundStyle(.tertiary)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        try? EnclaveKeyManager.shared.delete(keyID: k.id)
                        keys.removeAll { $0.id == k.id }
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
        .navigationTitle("Secure Enclave keys")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Generate") {
                    if let k = try? EnclaveKeyManager.shared.generate(label: "Termit – \(Date().formatted(date: .numeric, time: .shortened))") {
                        keys.append(k)
                    }
                }
            }
        }
        .onAppear { keys = EnclaveKeyManager.shared.listAll() }
    }
}
