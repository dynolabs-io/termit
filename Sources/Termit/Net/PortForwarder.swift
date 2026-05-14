import Foundation

struct PortForward: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case local
        case remote
        case socks
    }
    let id: UUID
    var kind: Kind
    var localPort: Int
    var remoteHost: String?
    var remotePort: Int?
    var description: String

    init(id: UUID = UUID(), kind: Kind, localPort: Int, remoteHost: String? = nil, remotePort: Int? = nil, description: String = "") {
        self.id = id
        self.kind = kind
        self.localPort = localPort
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.description = description
    }
}

actor PortForwarder {
    private let ssh: SSHClient
    private var active: [UUID: Task<Void, Error>] = [:]

    init(ssh: SSHClient) {
        self.ssh = ssh
    }

    func start(_ forward: PortForward) {
        let task = Task<Void, Error> {
            try Task.checkCancellation()
        }
        active[forward.id] = task
    }

    func stop(_ forward: PortForward) {
        active[forward.id]?.cancel()
        active.removeValue(forKey: forward.id)
    }

    func stopAll() {
        for (_, task) in active { task.cancel() }
        active.removeAll()
    }
}
