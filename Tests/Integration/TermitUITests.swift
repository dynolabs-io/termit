import XCTest

final class TermitUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testColdStartShowsHostList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Termit"].waitForExistence(timeout: 5))
    }

    func testCanOpenNewHostEditor() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Termit"].waitForExistence(timeout: 5))
        app.buttons["plus"].tap()
        XCTAssertTrue(app.navigationBars["New Host"].waitForExistence(timeout: 3))
    }

    func testCanFillAndSaveHost() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        app.buttons["plus"].tap()
        let alias = app.textFields["Alias"]
        XCTAssertTrue(alias.waitForExistence(timeout: 3))
        alias.tap(); alias.typeText("test-vps")
        app.textFields["Hostname or IP"].tap()
        app.typeText("203.0.113.42")
        app.textFields["Username"].tap()
        app.typeText("ci")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["test-vps"].waitForExistence(timeout: 3))
    }
}
