import Foundation

struct Host: Identifiable, Codable, Hashable {
    enum Auth: String, Codable, CaseIterable, Identifiable {
        case password
        case publicKey
        case agent
        var id: String { rawValue }
    }

    enum MoshPreference: String, Codable, CaseIterable, Identifiable {
        case auto
        case forceSSH
        case requireMosh
        var id: String { rawValue }
    }

    enum MoshInstallChoice: String, Codable {
        case unset
        case sshOnly
        case packageManager
        case portableBinary
    }

    let id: UUID
    var alias: String
    var hostname: String
    var port: Int
    var username: String
    var auth: Auth
    var keychainKeyID: String?
    var tags: [String]
    var moshPreference: MoshPreference
    var moshInstallChoice: MoshInstallChoice
    var moshUDPPortRange: ClosedRange<Int>
    var colorHex: String?
    var notes: String
    var lastConnected: Date?

    init(
        id: UUID = UUID(),
        alias: String,
        hostname: String,
        port: Int = 22,
        username: String,
        auth: Auth = .publicKey,
        keychainKeyID: String? = nil,
        tags: [String] = [],
        moshPreference: MoshPreference = .auto,
        moshInstallChoice: MoshInstallChoice = .unset,
        moshUDPPortRange: ClosedRange<Int> = 60000...61000,
        colorHex: String? = nil,
        notes: String = "",
        lastConnected: Date? = nil
    ) {
        self.id = id
        self.alias = alias
        self.hostname = hostname
        self.port = port
        self.username = username
        self.auth = auth
        self.keychainKeyID = keychainKeyID
        self.tags = tags
        self.moshPreference = moshPreference
        self.moshInstallChoice = moshInstallChoice
        self.moshUDPPortRange = moshUDPPortRange
        self.colorHex = colorHex
        self.notes = notes
        self.lastConnected = lastConnected
    }
}

extension Host {
    var displayHostname: String {
        port == 22 ? hostname : "\(hostname):\(port)"
    }
}
