import Foundation
import Citadel

actor SFTPClient {
    private let host: Host
    private var client: Citadel.SFTPClient?

    init(host: Host) {
        self.host = host
    }

    func connect() async throws {
        let ssh = try await Citadel.SSHClient.connect(
            host: host.hostname,
            port: host.port,
            authenticationMethod: try await Self.auth(for: host),
            hostKeyValidator: .acceptAnything(),
            reconnect: .never
        )
        self.client = try await ssh.openSFTP()
    }

    func list(_ path: String) async throws -> [SFTPEntry] {
        guard let c = client else { throw NSError(domain: "SFTP", code: 1) }
        let entries = try await c.listDirectory(atPath: path)
        return entries.flatMap { batch in
            batch.components.map { c in
                SFTPEntry(
                    name: c.filename,
                    isDirectory: c.attributes.permissions.map { ($0 & 0o170000) == 0o040000 } ?? false,
                    size: Int(c.attributes.size ?? 0),
                    modified: c.attributes.modificationTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
                )
            }
        }
    }

    func upload(local: URL, remote: String) async throws {
        guard let c = client else { throw NSError(domain: "SFTP", code: 1) }
        let data = try Data(contentsOf: local)
        let file = try await c.openFile(filePath: remote, flags: .write)
        try await file.write(ByteBuffer(data: data))
        try await file.close()
    }

    func download(remote: String, local: URL) async throws {
        guard let c = client else { throw NSError(domain: "SFTP", code: 1) }
        let file = try await c.openFile(filePath: remote, flags: .read)
        let data = try await file.readAll()
        try Data(buffer: data).write(to: local)
        try await file.close()
    }

    func delete(_ path: String) async throws {
        guard let c = client else { throw NSError(domain: "SFTP", code: 1) }
        try await c.remove(at: path)
    }

    func mkdir(_ path: String) async throws {
        guard let c = client else { throw NSError(domain: "SFTP", code: 1) }
        try await c.createDirectory(atPath: path)
    }

    func disconnect() async {
        try? await client?.close()
    }

    private static func auth(for host: Host) async throws -> SSHAuthenticationMethod {
        switch host.auth {
        case .password:
            let pw = try await CredentialStore.shared.fetchPassword(for: host)
            return .passwordBased(username: host.username, password: pw)
        case .publicKey, .agent:
            let pw = try await CredentialStore.shared.fetchPassword(for: host)
            return .passwordBased(username: host.username, password: pw)
        }
    }
}

struct SFTPEntry: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let isDirectory: Bool
    let size: Int
    let modified: Date?
}
