import Foundation
import NIOCore
import NIOPosix
import Citadel

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
    private let host: Host
    private var active: [UUID: ActiveForward] = [:]
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    init(host: Host) {
        self.host = host
    }

    func start(_ forward: PortForward) async throws {
        guard active[forward.id] == nil else { return }
        switch forward.kind {
        case .local:
            try await startLocal(forward)
        case .remote:
            try await startRemote(forward)
        case .socks:
            try await startSOCKS(forward)
        }
    }

    func stop(_ id: UUID) async {
        guard let entry = active[id] else { return }
        try? await entry.channel.close()
        active.removeValue(forKey: id)
    }

    func stopAll() async {
        for (_, entry) in active {
            try? await entry.channel.close()
        }
        active.removeAll()
    }

    private func startLocal(_ forward: PortForward) async throws {
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.eventLoop.makeSucceededVoidFuture()
            }
        let server = try await bootstrap.bind(host: "127.0.0.1", port: forward.localPort).get()
        active[forward.id] = ActiveForward(forward: forward, channel: server)
    }

    private func startRemote(_ forward: PortForward) async throws {
        // Remote forward implementation lives in the Citadel session bridge;
        // emit an entry so the UI sees it as "pending wiring".
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .childChannelInitializer { channel in channel.eventLoop.makeSucceededVoidFuture() }
        let server = try await bootstrap.bind(host: "127.0.0.1", port: 0).get()
        active[forward.id] = ActiveForward(forward: forward, channel: server)
    }

    private func startSOCKS(_ forward: PortForward) async throws {
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .childChannelInitializer { channel in channel.eventLoop.makeSucceededVoidFuture() }
        let server = try await bootstrap.bind(host: "127.0.0.1", port: forward.localPort).get()
        active[forward.id] = ActiveForward(forward: forward, channel: server)
    }

    private struct ActiveForward {
        let forward: PortForward
        let channel: Channel
    }
}
