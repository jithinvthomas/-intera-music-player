import XCTest

final class MusicPlayerUITests: XCTestCase {
    func testMenuAndPlayerFitOnScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-jizaAppearance", "light"]
        app.launch()
        let menu = app.buttons["Music menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        XCTAssertTrue(app.frame.contains(menu.frame))
        XCTAssertTrue(app.buttons["Play"].exists)
        XCTAssertTrue(app.frame.contains(app.buttons["Play"].frame))
        capture(app, name: "Jiza Cobalt Light")
        menu.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Choose folder"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Open audio file"].exists)
        app.buttons["Choose folder"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
    }

    func testDarkPlayerRemainsReachableInLandscape() {
        let app = XCUIApplication()
        app.launchArguments = ["-jizaAppearance", "dark"]
        app.launch()
        XCTAssertTrue(app.buttons["Music menu"].waitForExistence(timeout: 10))
        capture(app, name: "Jiza Cobalt Dark")
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.swipeUp()
        XCTAssertTrue(app.buttons["Play"].exists)
        app.buttons["Choose music folder"].swipeUp()
        XCTAssertTrue(app.buttons["Choose music folder"].isHittable)
        capture(app, name: "Jiza Cobalt Landscape")
        app.buttons["Choose music folder"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        app.buttons["Cancel"].tap()
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
