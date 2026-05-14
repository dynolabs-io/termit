import Foundation
import Citadel
import NIOCore

actor SFTPClient {
    private let host: Host
    private var ssh: Citadel.SSHClient?
    private var sftp: Citadel.SFTPClient?

    init(host: Host) {
        self.host = host
    }

    func connect() async throws {
        let auth: SSHAuthenticationMethod
        switch host.auth {
        case .password, .publicKey, .agent:
            let pw = (try? await CredentialStore.shared.fetchPassword(for: host)) ?? ""
            auth = .passwordBased(username: host.username, password: pw)
        }
        let s = try await Citadel.SSHClient.connect(
            host: host.hostname,
            port: host.port,
            authenticationMethod: auth,
            hostKeyValidator: .acceptAnything(),
            reconnect: .never
        )
        self.ssh = s
        self.sftp = try await s.openSFTP()
    }

    func list(_ path: String) async throws -> [SFTPEntry] {
        guard let sftp = sftp else { throw NSError(domain: "SFTP", code: 1) }
        let dir = try await sftp.listDirectory(atPath: path)
        var out: [SFTPEntry] = []
        for batch in dir {
            for c in batch.components {
                let perms = c.attributes.permissions ?? 0
                let isDir = (perms & 0o170000) == 0o040000
                out.append(SFTPEntry(
                    name: c.filename,
                    isDirectory: isDir,
                    size: Int(c.attributes.size ?? 0),
                    modified: c.attributes.modificationTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
                ))
            }
        }
        return out
    }

    func upload(local: URL, remote: String) async throws {
        guard let sftp = sftp else { throw NSError(domain: "SFTP", code: 1) }
        let data = try Data(contentsOf: local)
        var buf = ByteBufferAllocator().buffer(capacity: data.count)
        buf.writeBytes(data)
        let file = try await sftp.openFile(filePath: remote, flags: .write)
        try await file.write(buf)
        try await file.close()
    }

    func download(remote: String, local: URL) async throws {
        guard let sftp = sftp else { throw NSError(domain: "SFTP", code: 1) }
        let file = try await sftp.openFile(filePath: remote, flags: .read)
        let buf = try await file.readAll()
        try Data(buffer: buf).write(to: local)
        try await file.close()
    }

    func delete(_ path: String) async throws {
        guard let sftp = sftp else { throw NSError(domain: "SFTP", code: 1) }
        try await sftp.remove(at: path)
    }

    func mkdir(_ path: String) async throws {
        guard let sftp = sftp else { throw NSError(domain: "SFTP", code: 1) }
        try await sftp.createDirectory(atPath: path)
    }

    func disconnect() async {
        try? await ssh?.close()
    }
}

struct SFTPEntry: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let isDirectory: Bool
    let size: Int
    let modified: Date?
}
