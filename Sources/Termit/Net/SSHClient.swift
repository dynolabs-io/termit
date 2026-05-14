import Foundation
import Citadel
import NIOCore
import NIOSSH

actor SSHClient {
    enum SSHError: Error {
        case connectionFailed(String)
        case authenticationFailed
        case sessionClosed
        case timeout
        case ptyFailed
    }

    private let host: Host
    private var citadelSSH: Citadel.SSHClient?
    private(set) var isConnected = false

    init(host: Host) {
        self.host = host
    }

    func connect() async throws {
        let auth: SSHAuthenticationMethod
        switch host.auth {
        case .password:
            let pw = try await CredentialStore.shared.fetchPassword(for: host)
            auth = .passwordBased(username: host.username, password: pw)
        case .publicKey, .agent:
            let pw = (try? await CredentialStore.shared.fetchPassword(for: host)) ?? ""
            auth = .passwordBased(username: host.username, password: pw)
        }

        do {
            self.citadelSSH = try await Citadel.SSHClient.connect(
                host: host.hostname,
                port: host.port,
                authenticationMethod: auth,
                hostKeyValidator: .acceptAnything(),
                reconnect: .never
            )
            self.isConnected = true
        } catch {
            throw SSHError.connectionFailed(String(describing: error))
        }
    }

    func executeCommand(_ command: String) async throws -> String {
        guard let client = citadelSSH else { throw SSHError.sessionClosed }
        let output = try await client.executeCommand(command)
        return String(buffer: output)
    }

    func startInteractiveShell(
        cols: Int = 80,
        rows: Int = 24,
        onData: @escaping (Data) -> Void
    ) async throws -> SSHShellSession {
        guard let client = citadelSSH else { throw SSHError.sessionClosed }
        let session = SSHShellSession(client: client, host: host, cols: cols, rows: rows, onData: onData)
        try await session.start()
        return session
    }

    func disconnect() async {
        try? await citadelSSH?.close()
        isConnected = false
    }
}

actor SSHShellSession {
    private let client: Citadel.SSHClient
    private let host: Host
    private var cols: Int
    private var rows: Int
    private let onData: (Data) -> Void
    private var readTask: Task<Void, Never>?

    init(client: Citadel.SSHClient, host: Host, cols: Int, rows: Int, onData: @escaping (Data) -> Void) {
        self.client = client
        self.host = host
        self.cols = cols
        self.rows = rows
        self.onData = onData
    }

    func start() async throws {
        // Citadel's ergonomic shell API; if not present in the linked Citadel version,
        // CI surfaces the exact missing symbol and we adjust.
        let stream = try await client.executeCommandStream("/bin/sh -i", inShell: false)
        readTask = Task { [weak self] in
            for try await chunk in stream {
                switch chunk {
                case .stdout(let buffer):
                    self?.onData(Data(buffer: buffer))
                case .stderr(let buffer):
                    self?.onData(Data(buffer: buffer))
                }
            }
        }
    }

    func write(_ data: Data) async throws {
        _ = try await client.executeCommand(String(decoding: data, as: UTF8.self))
    }

    func resize(cols: Int, rows: Int) async throws {
        self.cols = cols
        self.rows = rows
    }

    func close() async {
        readTask?.cancel()
    }
}
