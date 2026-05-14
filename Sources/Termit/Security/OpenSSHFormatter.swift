import Foundation
import CryptoKit

enum OpenSSHFormatter {
    static func encode(p256 pubkey: P256.Signing.PublicKey) -> String {
        var blob = Data()
        appendSSHString("ecdsa-sha2-nistp256", to: &blob)
        appendSSHString("nistp256", to: &blob)
        let raw = pubkey.x963Representation
        appendSSHBytes(raw, to: &blob)
        return "ecdsa-sha2-nistp256 " + blob.base64EncodedString() + " termit"
    }

    static func encode(ed25519 pubkey: Curve25519.Signing.PublicKey) -> String {
        var blob = Data()
        appendSSHString("ssh-ed25519", to: &blob)
        appendSSHBytes(pubkey.rawRepresentation, to: &blob)
        return "ssh-ed25519 " + blob.base64EncodedString() + " termit"
    }

    private static func appendSSHString(_ s: String, to blob: inout Data) {
        appendSSHBytes(Data(s.utf8), to: &blob)
    }

    private static func appendSSHBytes(_ bytes: Data, to blob: inout Data) {
        var len = UInt32(bytes.count).bigEndian
        blob.append(Data(bytes: &len, count: 4))
        blob.append(bytes)
    }
}
