import SwiftUI

struct MoshInstallSheet: View {
    let probe: MoshServerInstaller.Probe
    let onChoose: (MoshInstallStrategy) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Detected") {
                    LabeledContent("Kernel", value: probe.kernel)
                    LabeledContent("Architecture", value: probe.arch)
                    LabeledContent("Distribution", value: probe.distro.rawValue)
                    if let v = probe.distroVersion { LabeledContent("Version", value: v) }
                    LabeledContent("Sudo available", value: probe.userHasSudo ? "yes" : "no")
                }
                Section("mosh-server is not installed on this host. Choose how to handle it:") {
                    ForEach(availableStrategies, id: \.self) { strategy in
                        Button {
                            onChoose(strategy)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Label(strategy.displayName, systemImage: icon(strategy))
                                    .font(.headline)
                                Text(strategy.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("mosh-server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onChoose(.sshOnly) }
                }
            }
        }
    }

    private var availableStrategies: [MoshInstallStrategy] {
        var list: [MoshInstallStrategy] = [.portableBinary, .sshOnly]
        if probe.userHasSudo && probe.distro != .unknown {
            list.insert(.packageManager, at: 0)
        }
        return list
    }

    private func icon(_ s: MoshInstallStrategy) -> String {
        switch s {
        case .sshOnly: return "terminal"
        case .packageManager: return "shippingbox"
        case .portableBinary: return "arrow.down.app"
        }
    }
}
