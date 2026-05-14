import Foundation
import NIO
import NIOSSH
import Citadel

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
    private var continuation: AsyncStream<String>.Continuation?
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
        case .publicKey:
            guard let keyID = host.keychainKeyID else { throw SSHError.authenticationFailed }
            let signer = try EnclaveSSHSigner(keyID: keyID)
            auth = .custom(username: host.username, offer: signer)
        case .agent:
            throw SSHError.authenticationFailed
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
        let pty = SSHPTYRequest(
            wantReply: true,
            term: "xterm-256color",
            terminalCharacterWidth: cols,
            terminalRowHeight: rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: SSHTerminalModes([:])
        )
        let shell = try await client.openShell(inheritEnvironment: false, pty: pty)
        let session = SSHShellSession(shell: shell, onData: onData)
        await session.start()
        return session
    }

    func disconnect() async {
        try? await citadelSSH?.close()
        isConnected = false
    }
}

actor SSHShellSession {
    private let shell: Citadel.TTYShell
    private let onData: (Data) -> Void
    private var readTask: Task<Void, Never>?

    init(shell: Citadel.TTYShell, onData: @escaping (Data) -> Void) {
        self.shell = shell
        self.onData = onData
    }

    func start() async {
        readTask = Task {
            for try await chunk in shell.stdout {
                onData(Data(buffer: chunk))
            }
        }
    }

    func write(_ data: Data) async throws {
        try await shell.write(ByteBuffer(data: data))
    }

    func resize(cols: Int, rows: Int) async throws {
        try await shell.resizePTY(width: cols, height: rows)
    }

    func close() async {
        readTask?.cancel()
        try? await shell.close()
    }
}

final class EnclaveSSHSigner: NIOSSHPublicKeyProtocol {
    let keyID: String
    init(keyID: String) throws {
        self.keyID = keyID
    }
    var publicKeyPrefix: String { "ecdsa-sha2-nistp256" }
    func write(to buffer: inout ByteBuffer) -> Int { 0 }
    func writeHostKey(to buffer: inout ByteBuffer) -> Int { 0 }
    func isValidSignature<DigestBytes>(_ signature: NIOSSHSignatureProtocol, for data: DigestBytes) -> Bool where DigestBytes : DataProtocol { false }
}
