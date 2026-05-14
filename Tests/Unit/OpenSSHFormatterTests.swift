import XCTest
import CryptoKit
@testable import Termit

final class OpenSSHFormatterTests: XCTestCase {
    func testEd25519Encoding() {
        let key = Curve25519.Signing.PrivateKey()
        let encoded = OpenSSHFormatter.encode(ed25519: key.publicKey)
        XCTAssertTrue(encoded.hasPrefix("ssh-ed25519 "))
        let parts = encoded.split(separator: " ")
        XCTAssertEqual(parts.count, 3)
        XCTAssertNotNil(Data(base64Encoded: String(parts[1])))
    }

    func testP256Encoding() {
        let key = P256.Signing.PrivateKey()
        let encoded = OpenSSHFormatter.encode(p256: key.publicKey)
        XCTAssertTrue(encoded.hasPrefix("ecdsa-sha2-nistp256 "))
    }
}
