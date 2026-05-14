import Foundation
import CloudKit
import CryptoKit

final class CloudKitHostSync {
    private let container: CKContainer
    private let database: CKDatabase
    private let zone = CKRecordZone(zoneName: "TermitZone")
    private let encryptionKey: SymmetricKey

    init() {
        self.container = CKContainer(identifier: "iCloud.io.dynolabs.termit")
        self.database = container.privateCloudDatabase
        self.encryptionKey = Self.loadOrCreateLocalKey()
    }

    func upload(_ host: Host) async throws {
        let record = CKRecord(recordType: "Host", recordID: CKRecord.ID(recordName: host.id.uuidString, zoneID: zone.zoneID))
        let encoded = try JSONEncoder().encode(host)
        let sealed = try ChaChaPoly.seal(encoded, using: encryptionKey)
        record["payload"] = sealed.combined
        try await database.save(record)
    }

    func delete(_ id: UUID) async throws {
        try await database.deleteRecord(withID: CKRecord.ID(recordName: id.uuidString, zoneID: zone.zoneID))
    }

    func observe(_ onChange: @escaping ([Host]) async -> Void) async {
        let query = CKQuery(recordType: "Host", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.zoneID = zone.zoneID
        var hosts: [Host] = []
        operation.recordMatchedBlock = { [weak self] _, result in
            guard let self = self else { return }
            switch result {
            case .success(let record):
                if let payload = record["payload"] as? Data,
                   let sealed = try? ChaChaPoly.SealedBox(combined: payload),
                   let raw = try? ChaChaPoly.open(sealed, using: self.encryptionKey),
                   let host = try? JSONDecoder().decode(Host.self, from: raw) {
                    hosts.append(host)
                }
            case .failure:
                break
            }
        }
        operation.queryResultBlock = { _ in
            Task { await onChange(hosts) }
        }
        database.add(operation)
    }

    private static func loadOrCreateLocalKey() -> SymmetricKey {
        let service = "io.dynolabs.termit.icloud-key"
        let account = "primary"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemAdd(add as CFDictionary, nil)
        return key
    }
}
