import Foundation
import Security

final class CredentialStore {
    static let shared = CredentialStore()
    private let service = "io.dynolabs.termit.passwords"

    func storePassword(_ password: String, for host: Host) throws {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: host.hostname,
            kSecAttrPort as String: host.port,
            kSecAttrAccount as String: host.username,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "CredentialStore", code: Int(status))
        }
    }

    func fetchPassword(for host: Host) async throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: host.hostname,
            kSecAttrPort as String: host.port,
            kSecAttrAccount as String: host.username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let s = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "CredentialStore", code: Int(status))
        }
        return s
    }
}
