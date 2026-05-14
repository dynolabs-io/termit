import Foundation
import Combine

@MainActor
final class HostStore: ObservableObject {
    @Published private(set) var hosts: [Host] = []
    private let storageURL: URL
    private let cloudSync: CloudKitHostSync?

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("hosts.json")
        self.cloudSync = Preferences.shared.iCloudSyncEnabled ? CloudKitHostSync() : nil
        load()
        Task { await cloudSync?.observe { [weak self] remoteHosts in
            await self?.merge(remoteHosts)
        } }
    }

    func add(_ host: Host) {
        hosts.append(host)
        persist()
        Task { try? await cloudSync?.upload(host) }
    }

    func update(_ host: Host) {
        guard let idx = hosts.firstIndex(where: { $0.id == host.id }) else { return }
        hosts[idx] = host
        persist()
        Task { try? await cloudSync?.upload(host) }
    }

    func delete(_ host: Host) {
        hosts.removeAll { $0.id == host.id }
        persist()
        Task { try? await cloudSync?.delete(host.id) }
    }

    func touchLastConnected(_ id: UUID) {
        guard let idx = hosts.firstIndex(where: { $0.id == id }) else { return }
        hosts[idx].lastConnected = Date()
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Host].self, from: data) else {
            return
        }
        self.hosts = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(hosts) else { return }
        try? data.write(to: storageURL, options: [.atomic, .completeFileProtection])
    }

    private func merge(_ remote: [Host]) async {
        var byID = Dictionary(uniqueKeysWithValues: hosts.map { ($0.id, $0) })
        for h in remote { byID[h.id] = h }
        hosts = Array(byID.values).sorted { $0.alias < $1.alias }
        persist()
    }
}
