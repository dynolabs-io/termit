import SwiftUI

struct TerminalSessionView: View {
    let host: Host
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var hostStore: HostStore
    @StateObject private var engine = TerminalEngine(rows: 24, cols: 80)
    @State private var showInstallSheet = false
    @State private var probe: MoshServerInstaller.Probe?
    @State private var installContinuation: CheckedContinuation<MoshInstallStrategy, Never>?
    @State private var didStart = false

    var body: some View {
        let session = sessionManager.session(for: host)
        return VStack(spacing: 0) {
            statusBar(session: session)
            TerminalView(engine: engine, host: host)
        }
        .navigationTitle(host.alias)
        .onAppear {
            guard !didStart else { return }
            didStart = true
            wireEngine(session: session)
            connect(session: session)
        }
        .sheet(isPresented: $showInstallSheet) {
            if let probe = probe {
                MoshInstallSheet(probe: probe) { strategy in
                    showInstallSheet = false
                    installContinuation?.resume(returning: strategy)
                    installContinuation = nil
                }
            }
        }
    }

    private func statusBar(session: ActiveSession) -> some View {
        HStack(spacing: 8) {
            Circle().fill(statusColor(session.status)).frame(width: 8, height: 8)
            Text(statusLabel(session.status)).font(.caption)
            Spacer()
            Button("Disconnect") {
                Task { await session.close() }
            }
            .disabled(session.status == .disconnected)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.thinMaterial)
    }

    private func statusColor(_ s: ActiveSession.Status) -> Color {
        switch s {
        case .moshConnected, .sshConnected: return .green
        case .connecting, .probingMosh, .installingMosh: return .yellow
        case .awaitingInstallChoice: return .orange
        case .error: return .red
        case .disconnected: return .gray
        }
    }

    private func statusLabel(_ s: ActiveSession.Status) -> String {
        switch s {
        case .moshConnected: return "Mosh"
        case .sshConnected: return "SSH"
        case .probingMosh: return "Probing…"
        case .installingMosh: return "Installing mosh-server…"
        case .awaitingInstallChoice: return "Awaiting install choice"
        case .connecting: return "Connecting…"
        case .error: return "Error"
        case .disconnected: return "Disconnected"
        }
    }

    private func wireEngine(session: ActiveSession) {
        engine.onSend = { data in
            Task { await session.send(data) }
        }
    }

    private func connect(session: ActiveSession) {
        Task {
            guard await BiometricGate.shared.requireForSession(host: host) else { return }
            await session.connect { probe in
                self.probe = probe
                self.showInstallSheet = true
                return await withCheckedContinuation { (cont: CheckedContinuation<MoshInstallStrategy, Never>) in
                    self.installContinuation = cont
                }
            }
            hostStore.touchLastConnected(host.id)
        }
    }
}
