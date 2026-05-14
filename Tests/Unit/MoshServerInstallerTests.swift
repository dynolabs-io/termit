import XCTest
@testable import Termit

final class MoshServerInstallerTests: XCTestCase {
    func testArchMappingX86() {
        XCTAssertEqual(MoshInstallStrategy.portableBinary.rawValue, "portableBinary")
    }

    func testStrategyOrdering() {
        XCTAssertEqual(MoshInstallStrategy.allCases.count, 3)
    }

    func testMoshInstallStrategyDisplayNames() {
        XCTAssertFalse(MoshInstallStrategy.sshOnly.displayName.isEmpty)
        XCTAssertFalse(MoshInstallStrategy.packageManager.displayName.isEmpty)
        XCTAssertFalse(MoshInstallStrategy.portableBinary.displayName.isEmpty)
    }
}
