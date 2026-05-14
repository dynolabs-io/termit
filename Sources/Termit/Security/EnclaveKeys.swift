import Foundation
import CryptoKit
import Security
import LocalAuthentication

enum EnclaveError: Error {
    case enclaveUnavailable
    case keyGenerationFailed(OSStatus)
    case keyNotFound
    case signingFailed
    case exportFailed
}

struct EnclaveKey: Identifiable, Codable, Hashable {
    enum Algorithm: String, Codable {
        case ed25519
        case ecdsaP256
    }

    let id: String
    let label: String
    let algorithm: Algorithm
    let publicKeyOpenSSH: String
    let publicKeySHA256: String
    let createdAt: Date
}

final class EnclaveKeyManager {
    static let shared = EnclaveKeyManager()
    private let service = "io.dynolabs.termit.enclave"

    func isSupported() -> Bool {
        SecureEnclave.isAvailable
    }

    func generate(label: String, algorithm: EnclaveKey.Algorithm = .ecdsaP256) throws -> EnclaveKey {
        guard isSupported() else { throw EnclaveError.enclaveUnavailable }
        let id = UUID().uuidString

        switch algorithm {
        case .ecdsaP256:
            let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.privateKeyUsage, .biometryCurrentSet],
                nil
            )!
            let privateKey = try SecureEnclave.P256.Signing.PrivateKey(
                accessControl: access,
                authenticationContext: nil
            )
            try storeECDSAKey(privateKey, id: id, label: label)
            let pubOpenSSH = OpenSSHFormatter.encode(p256: privateKey.publicKey)
            let sha = Insecure.SHA256.hash(data: Data(pubOpenSSH.utf8)).hexString
            return EnclaveKey(
                id: id,
                label: label,
                algorithm: .ecdsaP256,
                publicKeyOpenSSH: pubOpenSSH,
                publicKeySHA256: sha,
                createdAt: Date()
            )
        case .ed25519:
            let key = Curve25519.Signing.PrivateKey()
            try KeyStore.shared.storeEd25519(key, id: id, label: label)
            let pubOpenSSH = OpenSSHFormatter.encode(ed25519: key.publicKey)
            let sha = Insecure.SHA256.hash(data: Data(pubOpenSSH.utf8)).hexString
            return EnclaveKey(
                id: id,
                label: label,
                algorithm: .ed25519,
                publicKeyOpenSSH: pubOpenSSH,
                publicKeySHA256: sha,
                createdAt: Date()
            )
        }
    }

    func sign(challenge: Data, keyID: String) throws -> Data {
        guard let pk = try KeyStore.shared.loadECDSA(id: keyID) else {
            throw EnclaveError.keyNotFound
        }
        return try pk.signature(for: challenge).rawRepresentation
    }

    func delete(keyID: String) throws {
        try KeyStore.shared.delete(id: keyID)
    }

    func listAll() -> [EnclaveKey] {
        KeyStore.shared.listKeyMetadata()
    }

    private func storeECDSAKey(_ key: SecureEnclave.P256.Signing.PrivateKey, id: String, label: String) throws {
        try KeyStore.shared.storeECDSA(key, id: id, label: label)
    }
}

extension Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
