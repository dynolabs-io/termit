import Foundation
import CryptoKit
import Security

final class KeyStore {
    static let shared = KeyStore()
    private let service = "io.dynolabs.termit.keys"
    private let metadataKey = "io.dynolabs.termit.keys.metadata"

    func storeECDSA(_ key: SecureEnclave.P256.Signing.PrivateKey, id: String, label: String) throws {
        let representation = key.dataRepresentation
        try writeKeychain(account: id, data: representation, label: label, type: "ecdsa")
        saveMetadata(
            EnclaveKey(
                id: id,
                label: label,
                algorithm: .ecdsaP256,
                publicKeyOpenSSH: OpenSSHFormatter.encode(p256: key.publicKey),
                publicKeySHA256: Insecure.SHA256.hash(data: key.publicKey.rawRepresentation).hexString,
                createdAt: Date()
            )
        )
    }

    func storeEd25519(_ key: Curve25519.Signing.PrivateKey, id: String, label: String) throws {
        let representation = key.rawRepresentation
        try writeKeychain(account: id, data: representation, label: label, type: "ed25519")
        saveMetadata(
            EnclaveKey(
                id: id,
                label: label,
                algorithm: .ed25519,
                publicKeyOpenSSH: OpenSSHFormatter.encode(ed25519: key.publicKey),
                publicKeySHA256: Insecure.SHA256.hash(data: key.publicKey.rawRepresentation).hexString,
                createdAt: Date()
            )
        )
    }

    func loadECDSA(id: String) throws -> SecureEnclave.P256.Signing.PrivateKey? {
        guard let data = try readKeychain(account: id) else { return nil }
        return try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: data)
    }

    func loadEd25519(id: String) throws -> Curve25519.Signing.PrivateKey? {
        guard let data = try readKeychain(account: id) else { return nil }
        return try Curve25519.Signing.PrivateKey(rawRepresentation: data)
    }

    func delete(id: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EnclaveError.keyGenerationFailed(status)
        }
        var metas = loadMetadataList()
        metas.removeAll { $0.id == id }
        persistMetadataList(metas)
    }

    func listKeyMetadata() -> [EnclaveKey] {
        loadMetadataList()
    }

    private func writeKeychain(account: String, data: Data, label: String, type: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrLabel as String: label,
            kSecAttrType as String: type,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EnclaveError.keyGenerationFailed(status)
        }
    }

    private func readKeychain(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { return nil }
            throw EnclaveError.keyGenerationFailed(status)
        }
        return result as? Data
    }

    private func saveMetadata(_ key: EnclaveKey) {
        var existing = loadMetadataList()
        existing.removeAll { $0.id == key.id }
        existing.append(key)
        persistMetadataList(existing)
    }

    private func loadMetadataList() -> [EnclaveKey] {
        guard let url = metadataURL,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([EnclaveKey].self, from: data) else { return [] }
        return decoded
    }

    private func persistMetadataList(_ keys: [EnclaveKey]) {
        guard let url = metadataURL, let data = try? JSONEncoder().encode(keys) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    private var metadataURL: URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("enclave-keys.json")
    }
}
