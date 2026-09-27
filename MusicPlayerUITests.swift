import XCTest

final class MusicPlayerUITests: XCTestCase {
    func testMenuAndPlayerFitOnScreen() {
        let app = XCUIApplication()
        app.launch()
        let menu = app.buttons["Music menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        XCTAssertTrue(app.frame.contains(menu.frame))
        XCTAssertTrue(app.buttons["Play"].exists)
        XCTAssertTrue(app.frame.contains(app.buttons["Play"].frame))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Intera player"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        // Tap the visible control directly; XCTest cannot scroll SwiftUI Menu into view.
        menu.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Choose folder"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Open audio file"].exists)
        app.buttons["Choose folder"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
    }
}
