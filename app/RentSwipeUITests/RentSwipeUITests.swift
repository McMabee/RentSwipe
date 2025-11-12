//
//  RentSwipeUITests.swift
//  RentSwipeUITests
//
//  Created by Codex CLI.
//

import XCTest

final class RentSwipeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["RentSwipe"].exists)
    }
}
