import XCTest

final class MusicPlayerUITests: XCTestCase {
    func testMenuAndPlayerFitOnScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-jizaAppearance", "light"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        let menu = app.buttons["Music menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        XCTAssertTrue(app.frame.contains(menu.frame))
        let play = app.buttons["Play"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        XCTAssertTrue(app.frame.contains(play.frame))
        capture(app, name: "Jiza Cobalt Light")
        menu.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Choose folder"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Open audio file"].exists)
        app.buttons["Choose folder"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
