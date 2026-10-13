//
//  egunHoldingsUITests.swift
//  egunHoldingsUITests
//
//  Created by 엄지용 on 3/24/26.
//

import XCTest

final class egunHoldingsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    /// iPhone 12 mini(360pt 폭)에서도 데모의 세 핵심 탭이 가로로 잘리지 않는지 확인한다.
    /// 이 테스트는 iOS 26 이상 iPhone 12 mini 시뮬레이터에서 실행한다.
    @MainActor
    func testMainTabsKeepVisibleContentWithinScreenWidth() throws {
        let tabCases = [
            (launchValue: "today", title: "오늘"),
            (launchValue: "newsroom", title: "뉴스룸"),
            (launchValue: "asset", title: "내 자산"),
        ]

        for tabCase in tabCases {
            let app = XCUIApplication()
            app.launchArguments = [
                "-ui-testing-main-tabs",
                "-ui-testing-main-tab",
                tabCase.launchValue,
            ]
            app.launch()

            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3))
            XCTAssertEqual(app.frame.width, 360, accuracy: 1, "iPhone 12 mini(360pt 폭)에서 실행해야 합니다.")
            XCTAssertTrue(app.staticTexts[tabCase.title].waitForExistence(timeout: 5), "\(tabCase.title) 화면을 찾을 수 없습니다.")
            assertVisibleElementsStayWithinAppWidth(in: app, tabLabel: tabCase.title)
            attachScreenshot(of: app, named: "iPhone 12 mini - \(tabCase.title)")
            app.terminate()
        }
    }

    @MainActor
    func testNewsroomMetricsAndDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-main-tabs", "-ui-testing-main-tab", "newsroom"]
        app.launch()
        let apple = app.buttons["newsroom.holding.AAPL"]
        XCTAssertTrue(apple.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["총자산 기준 18%"].exists)
        let nvidia = app.buttons["newsroom.holding.NVDA"]
        XCTAssertLessThan(apple.frame.minY, nvidia.frame.minY)
        let quietRow = app.descendants(matching: .any)["newsroom.holding.QQQ"]
        XCTAssertTrue(quietRow.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["newsroom.holding.QQQ"].exists)
        quietRow.tap()
        XCTAssertTrue(app.staticTexts["내 보유 종목"].waitForExistence(timeout: 3))
        attachScreenshot(of: app, named: "Newsroom - sorted holdings and allocation")
        apple.tap()
        XCTAssertTrue(app.staticTexts["내 자산의 18%"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["오늘 -0.6%"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "총자산 기준")).firstMatch.exists)
        // iOS 유리 효과의 AdditionalDimmingOverlay는 화면 밖으로 확장되는 시스템 장식이다.
        // 실제 상세 텍스트의 레이아웃 경계를 검사한다.
        for text in app.staticTexts.allElementsBoundByIndex where text.isHittable {
            XCTAssertGreaterThanOrEqual(text.frame.minX, app.frame.minX - 1)
            XCTAssertLessThanOrEqual(text.frame.maxX, app.frame.maxX + 1)
        }
        attachScreenshot(of: app, named: "Newsroom - detail daily change and allocation")
    }

    @MainActor
    private func assertVisibleElementsStayWithinAppWidth(
        in app: XCUIApplication,
        tabLabel: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let appFrame = app.frame
        let tolerance: CGFloat = 1
        let overflowingElements = app.descendants(matching: .any).allElementsBoundByIndex.filter { element in
            let frame = element.frame
            let isVerticallyVisible = frame.maxY > appFrame.minY && frame.minY < appFrame.maxY
            let extendsPastHorizontalBounds = frame.minX < appFrame.minX - tolerance
                || frame.maxX > appFrame.maxX + tolerance

            return element.exists && !frame.isEmpty && isVerticallyVisible && extendsPastHorizontalBounds
        }

        XCTAssertTrue(
            overflowingElements.isEmpty,
            "\(tabLabel) 탭에서 화면 폭을 벗어난 요소: \(overflowingElements.map(\.description).joined(separator: ", "))",
            file: file,
            line: line
        )
    }

    @MainActor
    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
