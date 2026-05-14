import XCTest
@testable import Termit

final class HostTests: XCTestCase {
    func testHostRoundTripCodable() throws {
        let h = Host(alias: "prod-edge-1", hostname: "10.0.0.5", username: "ops", tags: ["prod", "edge"])
        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(Host.self, from: data)
        XCTAssertEqual(h.id, decoded.id)
        XCTAssertEqual(h.alias, decoded.alias)
        XCTAssertEqual(h.tags, decoded.tags)
    }

    func testDisplayHostnameOmitsDefaultPort() {
        let h = Host(alias: "h", hostname: "example.com", port: 22, username: "u")
        XCTAssertEqual(h.displayHostname, "example.com")
    }

    func testDisplayHostnameIncludesNonDefaultPort() {
        let h = Host(alias: "h", hostname: "example.com", port: 2222, username: "u")
        XCTAssertEqual(h.displayHostname, "example.com:2222")
    }
}
