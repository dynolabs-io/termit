import XCTest
@testable import Termit

final class SnippetTests: XCTestCase {
    func testRenderedCommandSubstitutesVariables() {
        let host = Host(alias: "edge", hostname: "edge.example.com", username: "admin")
        let s = Snippet(name: "ping", command: "echo connecting to $HOST as $USER")
        XCTAssertEqual(s.renderedCommand(for: host), "echo connecting to edge.example.com as admin")
    }

    func testAppliesToWhenTagsMatch() {
        let host = Host(alias: "edge", hostname: "h", username: "u", tags: ["prod", "edge"])
        let s = Snippet(name: "n", command: "c", tagsScope: ["prod"])
        XCTAssertTrue(s.appliesTo(host: host))
    }

    func testAppliesToFalseWhenTagsDisjoint() {
        let host = Host(alias: "edge", hostname: "h", username: "u", tags: ["staging"])
        let s = Snippet(name: "n", command: "c", tagsScope: ["prod"])
        XCTAssertFalse(s.appliesTo(host: host))
    }
}
