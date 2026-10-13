import XCTest

@MainActor
final class SignupEmailUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testFullEmailEnablesSendAndDisablesOriginalField() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-signup-email"]
        app.launch()

        let local = app.textFields["signup.emailLocalPart"]
        let send = app.buttons["인증번호 보내기"]
        XCTAssertTrue(local.waitForExistence(timeout: 5))
        XCTAssertTrue(local.isEnabled)
        XCTAssertFalse(send.isEnabled)

        local.tap()
        local.typeText("original")
        XCTAssertTrue(send.isEnabled)
        app.buttons["signup.emailDomain"].tap()
        app.buttons["직접 입력"].tap()

        let full = app.textFields["signup.fullEmailAddress"]
        XCTAssertTrue(full.waitForExistence(timeout: 3))
        XCTAssertFalse(local.isEnabled)
        XCTAssertTrue(full.isEnabled)
        XCTAssertFalse(send.isEnabled)
        full.tap()
        full.typeText("tester@example.com")
        XCTAssertTrue(send.isEnabled)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "full email enables verification and original field is disabled"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        full.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "tester@example.com".count))
        full.typeText("invalid")
        XCTAssertFalse(send.isEnabled)

        app.buttons["signup.emailDomain"].tap()
        app.buttons["naver.com"].tap()
        XCTAssertFalse(full.exists)
        XCTAssertTrue(local.isEnabled)
        XCTAssertEqual(local.value as? String, "original")
        XCTAssertTrue(send.isEnabled)
    }
}
