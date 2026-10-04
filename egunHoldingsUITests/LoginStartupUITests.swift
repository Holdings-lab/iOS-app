import XCTest

/// Optional live smoke test; credentials are supplied to the runner, never kept in the repository.
final class LoginStartupUITests: XCTestCase {
    func testFreshLoginAndRapidTabSwitching() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let email = environment["LIVE_SMOKE_EMAIL"],
              let password = environment["LIVE_SMOKE_PASSWORD"] else {
            throw XCTSkip("Live account credentials were not supplied")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let emailField = app.textFields["이메일 주소"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 15))
        emailField.tap()
        emailField.typeText(email)
        let passwordField = app.secureTextFields.firstMatch
        passwordField.tap()
        passwordField.typeText(password)
        app.buttons["로그인"].tap()
        XCTAssertTrue(app.tabBars.buttons["오늘"].waitForExistence(timeout: 20))
        for tab in ["뉴스룸", "내 자산", "오늘", "뉴스룸", "오늘", "내 자산", "오늘"] {
            app.tabBars.buttons[tab].tap()
        }
        // Wait for the slowest normal API without blocking other tab navigation.
        XCTAssertTrue(app.tabBars.buttons["뉴스룸"].waitForExistence(timeout: 40))
        app.tabBars.buttons["뉴스룸"].tap()
        let newsroom = XCTAttachment(screenshot: app.screenshot())
        newsroom.name = "live-newsroom-after-tab-switch"
        newsroom.lifetime = .keepAlways
        add(newsroom)
        app.tabBars.buttons["내 자산"].tap()
        let assets = XCTAttachment(screenshot: app.screenshot())
        assets.name = "live-assets-after-tab-switch"
        assets.lifetime = .keepAlways
        add(assets)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["오늘"].waitForExistence(timeout: 20))
    }
}
