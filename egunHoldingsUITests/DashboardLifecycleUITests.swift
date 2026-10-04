import XCTest

@MainActor
final class DashboardLifecycleUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testGoalButtonOpensSettingsAndUpdatesToday() {
        let app = launchDashboard()
        let goalButton = app.buttons["목표 설정하기"]
        scrollTo(goalButton, in: app)
        goalButton.tap()
        XCTAssertTrue(app.staticTexts["목표 설정"].waitForExistence(timeout: 4))
        let house = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "내 집 마련")).firstMatch
        XCTAssertTrue(house.exists)
        house.tap()
        app.buttons["저장"].tap()
        XCTAssertTrue(app.buttons["변경 저장"].waitForExistence(timeout: 3))
        app.buttons["변경 저장"].tap()
        XCTAssertTrue(app.buttons["설정 닫기"].waitForExistence(timeout: 3))
        app.buttons["설정 닫기"].tap()
        XCTAssertTrue(app.tabBars.buttons["오늘"].isSelected)
        let percent = app.staticTexts["45%"]
        scrollTo(percent, in: app)
        XCTAssertTrue(percent.exists)
        XCTAssertFalse(app.buttons["목표 설정하기"].exists)
        attach(app, name: "goal saved and reflected on Today")
    }

    func testRefreshControlsEndAfterSwitchingTabsAndNewsStaySynced() {
        let app = launchDashboard()
        let news = app.staticTexts["UI 서버 뉴스 1"]
        scrollTo(news, in: app)
        XCTAssertTrue(news.waitForExistence(timeout: 4))
        for _ in 0..<3 {
            if app.buttons["설정"].isHittable { break }
            app.scrollViews.firstMatch.swipeDown()
        }
        pullToRefresh(app)
        XCTAssertTrue(waitForRefreshCount(1, in: app))
        app.tabBars.buttons["뉴스룸"].tap()
        XCTAssertTrue(app.buttons["newsroom.holding.NVDA"].waitForExistence(timeout: 4))
        app.tabBars.buttons["오늘"].tap()
        XCTAssertTrue(waitForRefreshCount(0, in: app))
        attach(app, name: "Today after returning during refresh")
        let secondNews = app.staticTexts["UI 서버 뉴스 2"]
        scrollTo(secondNews, in: app)
        XCTAssertTrue(secondNews.waitForExistence(timeout: 8))

        app.tabBars.buttons["뉴스룸"].tap()
        XCTAssertTrue(app.staticTexts["UI 서버 뉴스 2"].waitForExistence(timeout: 4))
        pullToRefresh(app)
        XCTAssertTrue(waitForRefreshCount(1, in: app))
        app.tabBars.buttons["오늘"].tap()
        app.tabBars.buttons["뉴스룸"].tap()
        XCTAssertTrue(waitForRefreshCount(0, in: app))
        XCTAssertTrue(app.staticTexts["UI 서버 뉴스 3"].waitForExistence(timeout: 8))
        attach(app, name: "Newsroom after returning during refresh")
        app.tabBars.buttons["오늘"].tap()
        let thirdNews = app.staticTexts["UI 서버 뉴스 3"]
        scrollTo(thirdNews, in: app)
        XCTAssertTrue(thirdNews.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForRefreshCount(0, in: app))
        attach(app, name: "latest Newsroom response shared with Today")
    }

    private func launchDashboard() -> XCUIApplication {
        let app = XCUIApplication()
        // XCTest가 refresh 애니메이션이 끝날 때까지 기다리면 '진행 중 탭 전환'을 검사할 수 없다.
        // 테스트 러너의 자동 대기만 끄며 앱의 애니메이션/요청은 실제로 계속 실행한다.
        let selector = NSSelectorFromString("setShouldWaitForQuiescence:")
        XCTAssertTrue(app.responds(to: selector))
        app.setValue(false, forKey: "shouldWaitForQuiescence")
        app.launchArguments = ["-ui-testing-dashboard-refresh"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["오늘"].waitForExistence(timeout: 5))
        return app
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 {
            if element.exists && element.isHittable { return }
            app.scrollViews.firstMatch.swipeUp()
        }
    }

    private func pullToRefresh(_ app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
            .press(forDuration: 0.1, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)))
    }

    private func waitForRefreshCount(_ count: Int, in app: XCUIApplication) -> Bool {
        let predicate = NSPredicate(format: "label == %@", "활성 새로고침: \(count)")
        return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate,
                                                            object: app.staticTexts["ui.refreshControlCount"])],
                              timeout: 3) == .completed
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
