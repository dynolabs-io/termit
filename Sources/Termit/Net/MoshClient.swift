import Foundation
import Network

actor MoshClient {
    enum MoshError: Error {
        case bootstrapFailed(String)
        case udpHandshakeFailed
        case sessionClosed
    }

    private let host: Host
    private let onData: (Data) -> Void
    private let onStateChange: (NWConnection.State) -> Void
    private var udp: NWConnection?
    private var pathMonitor: NWPathMonitor?
    private var moshKey: String = ""
    private var moshUDPPort: Int = 0
    private(set) var isAlive = false

    init(
        host: Host,
        onData: @escaping (Data) -> Void,
        onStateChange: @escaping (NWConnection.State) -> Void
    ) {
        self.host = host
        self.onData = onData
        self.onStateChange = onStateChange
    }

    func start() async throws {
        let ssh = SSHClient(host: host)
        try await ssh.connect()
        let serverCmd = "mosh-server new -p \(host.moshUDPPortRange.lowerBound):\(host.moshUDPPortRange.upperBound)"
        let response = try await ssh.executeCommand(serverCmd)
        guard let (port, key) = parseMoshConnect(response) else {
            await ssh.disconnect()
            throw MoshError.bootstrapFailed(response)
        }
        await ssh.disconnect()
        self.moshUDPPort = port
        self.moshKey = key
        try await openUDP()
        startPathMonitor()
        isAlive = true
    }

    func send(_ data: Data) async throws {
        guard let udp = udp else { throw MoshError.sessionClosed }
        let payload = MoshFraming.encrypt(data: data, key: moshKey)
        return try await withCheckedThrowingContinuation { cont in
            udp.send(content: payload, completion: .contentProcessed { err in
                if let err = err { cont.resume(throwing: err) } else { cont.resume() }
            })
        }
    }

    func close() async {
        pathMonitor?.cancel()
        udp?.cancel()
        isAlive = false
    }

    private func parseMoshConnect(_ raw: String) -> (Int, String)? {
        let line = raw.split(separator: "\n").first(where: { $0.contains("MOSH CONNECT") })
        guard let line = line else { return nil }
        let parts = line.split(separator: " ")
        guard parts.count >= 4, let port = Int(parts[2]) else { return nil }
        let key = String(parts[3])
        return (port, key)
    }

    private func openUDP() async throws {
        let params = NWParameters.udp
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host.hostname),
            port: NWEndpoint.Port(rawValue: UInt16(moshUDPPort))!
        )
        let conn = NWConnection(to: endpoint, using: params)
        self.udp = conn

        conn.stateUpdateHandler = { [weak self] state in
            self?.onStateChange(state)
        }
        conn.start(queue: .global(qos: .userInitiated))
        receiveLoop(conn)
    }

    private func receiveLoop(_ conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, _ in
            guard let self = self else { return }
            if let data = data {
                let decrypted = MoshFraming.decrypt(data: data, key: self.moshKey)
                Task { await self.deliver(decrypted) }
            }
            self.receiveLoop(conn)
        }
    }

    private func deliver(_ data: Data) {
        onData(data)
    }

    private func startPathMonitor() {
        let monitor = NWPathMonitor()
        self.pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { await self?.reroamUDP() }
        }
        monitor.start(queue: .global(qos: .background))
    }

    private func reroamUDP() async {
        guard let udp = udp else { return }
        udp.viabilityUpdateHandler?(true)
    }
}

enum MoshFraming {
    static func encrypt(data: Data, key: String) -> Data {
        return data
    }

    static func decrypt(data: Data, key: String) -> Data {
        return data
    }
}
