import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var activeSessions: [UUID: ActiveSession] = [:]

    func session(for host: Host) -> ActiveSession {
        if let existing = activeSessions[host.id] { return existing }
        let s = ActiveSession(host: host)
        activeSessions[host.id] = s
        return s
    }

    func close(host: Host) async {
        if let s = activeSessions[host.id] {
            await s.close()
        }
        activeSessions.removeValue(forKey: host.id)
    }

    func closeAll() async {
        for (_, s) in activeSessions { await s.close() }
        activeSessions.removeAll()
    }
}

@MainActor
final class ActiveSession: ObservableObject, Identifiable {
    let id = UUID()
    let host: Host
    @Published var status: Status = .disconnected
    @Published var lastError: String?
    @Published var transcript: Data = Data()

    enum Status: String {
        case disconnected
        case connecting
        case probingMosh
        case awaitingInstallChoice
        case installingMosh
        case sshConnected
        case moshConnected
        case error
    }

    private var ssh: SSHClient?
    private var mosh: MoshClient?
    private var shell: SSHShellSession?

    init(host: Host) {
        self.host = host
    }

    func connect(install handler: @escaping (MoshServerInstaller.Probe) async -> MoshInstallStrategy) async {
        status = .connecting
        do {
            let ssh = SSHClient(host: host)
            self.ssh = ssh
            try await ssh.connect()
            status = .probingMosh
            let installer = MoshServerInstaller(ssh: ssh)
            let probe = try await installer.probe()
            if probe.hasMoshServer || probe.portablePath != nil {
                try await startMosh()
                status = .moshConnected
            } else if host.moshInstallChoice != .unset {
                try await applyStoredInstallChoice(installer: installer, probe: probe)
            } else {
                status = .awaitingInstallChoice
                let choice = await handler(probe)
                try await installer.install(strategy: choice, probe: probe)
                if choice == .sshOnly {
                    try await startInteractiveSSH()
                    status = .sshConnected
                } else {
                    try await startMosh()
                    status = .moshConnected
                }
            }
        } catch {
            lastError = String(describing: error)
            status = .error
        }
    }

    func send(_ data: Data) async {
        if let mosh = mosh { try? await mosh.send(data) }
        else if let shell = shell { try? await shell.write(data) }
    }

    func close() async {
        await mosh?.close()
        await shell?.close()
        await ssh?.disconnect()
        status = .disconnected
    }

    private func applyStoredInstallChoice(installer: MoshServerInstaller, probe: MoshServerInstaller.Probe) async throws {
        switch host.moshInstallChoice {
        case .sshOnly:
            try await startInteractiveSSH()
            status = .sshConnected
        case .packageManager:
            try await installer.install(strategy: .packageManager, probe: probe)
            try await startMosh()
            status = .moshConnected
        case .portableBinary:
            try await installer.install(strategy: .portableBinary, probe: probe)
            try await startMosh()
            status = .moshConnected
        case .unset:
            break
        }
    }

    private func startMosh() async throws {
        let mosh = MoshClient(
            host: host,
            onData: { [weak self] data in
                Task { @MainActor in self?.appendTranscript(data) }
            },
            onStateChange: { _ in }
        )
        try await mosh.start()
        self.mosh = mosh
    }

    private func startInteractiveSSH() async throws {
        guard let ssh = ssh else { return }
        let shell = try await ssh.startInteractiveShell(cols: 80, rows: 24) { [weak self] data in
            Task { @MainActor in self?.appendTranscript(data) }
        }
        self.shell = shell
    }

    private func appendTranscript(_ data: Data) {
        transcript.append(data)
    }
}
