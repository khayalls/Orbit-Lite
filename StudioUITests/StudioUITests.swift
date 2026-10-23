import XCTest

@MainActor
final class StudioUITests: XCTestCase {
    func testToolbarAndStudioPanels() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Style"].waitForExistence(timeout: 25), app.debugDescription)
        app.buttons["Style"].tap()
        XCTAssertTrue(app.staticTexts["Make it yours"].waitForExistence(timeout: 8))
        app.buttons["Atom"].tap()
        app.buttons["Iris"].tap()
        app.buttons["Chrome"].tap()
        app.buttons["Done"].tap()
        app.buttons["Orbit"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        app.buttons["Gestures"].tap()
        XCTAssertTrue(app.staticTexts["Two-hand stretch"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["Reset"].tap()
        XCTAssertTrue(app.buttons["Orbit"].waitForExistence(timeout: 5))
        app.buttons["Style"].tap()
        XCTAssertTrue(app.staticTexts["Saturn · Pearl · Azure"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["Orbit"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
    }

    func testPalmDockExpansionAndReturnPreserveSculpture() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Collapse toolbar"].waitForExistence(timeout: 25))
        app.buttons["Collapse toolbar"].tap()
        XCTAssertTrue(app.buttons["Expand toolbar"].waitForExistence(timeout: 5))
        app.buttons["Expand toolbar"].tap()
        app.buttons["Preview palm dock"].tap()
        XCTAssertTrue(app.staticTexts["Palm dock preview"].waitForExistence(timeout: 12), app.debugDescription)
        XCTAssertTrue(app.buttons["Expand toolbar"].waitForExistence(timeout: 8), app.debugDescription)
        app.buttons["Expand toolbar"].tap()
        XCTAssertTrue(app.staticTexts["PALM PREVIEW"].waitForExistence(timeout: 5), app.debugDescription)
        app.buttons["Style"].tap()
        XCTAssertTrue(app.staticTexts["Make it yours"].waitForExistence(timeout: 5))
        app.buttons["Atom"].tap()
        app.buttons["Jade"].tap()
        app.buttons["Chrome"].tap()
        app.buttons["Done"].tap()
        app.buttons["Collapse toolbar"].tap()
        XCTAssertTrue(app.buttons["Expand toolbar"].waitForExistence(timeout: 5))
        app.buttons["Float toolbar"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Preview palm dock"].waitForExistence(timeout: 8))
        app.buttons["Style"].tap()
        XCTAssertTrue(app.staticTexts["Atom · Chrome · Jade"].waitForExistence(timeout: 5))
    }

}
