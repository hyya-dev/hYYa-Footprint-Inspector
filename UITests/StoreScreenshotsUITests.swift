// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest

/// Captures the raw screens for the App Store slides. Run it on a Simulator (never a real phone:
/// a real device's values, such as its vendor ID, must not end up in public screenshots).
///
///   xcodebuild test -scheme "hYYa Footprint Inspector UITests" \
///     -only-testing:hYYaFootprintInspectorUITests/StoreScreenshotsUITests \
///     -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" -resultBundlePath …
///
/// Each screen is attached as `store-NN-name`. `scripts/make-store-slides.py` turns them into slides.
final class StoreScreenshotsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    private func shot(_ name: String) {
        sleep(1)
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func tap(_ label: String, timeout: TimeInterval = 8) {
        let el = app.buttons[label].firstMatch
        if el.waitForExistence(timeout: timeout) {
            el.tap()
        } else {
            let alt = app.staticTexts[label].firstMatch
            if alt.waitForExistence(timeout: 2) { alt.tap() }
        }
    }

    /// Tabs are a bottom tab bar on iPhone and a floating bar at the top on iPad.
    private func tab(_ name: String) {
        let bar = app.tabBars.buttons[name]
        if bar.exists { bar.tap() } else { app.buttons[name].firstMatch.tap() }
    }

    private func scrollTo(_ element: XCUIElement, max: Int = 10) {
        var n = 0
        while !element.isHittable && n < max { app.swipeUp(velocity: .slow); n += 1 }
    }

    /// The Settings screen from top to bottom, attached as `settings-1…`, for design review.
    func testCaptureSettings() {
        app.launch()
        sleep(2)
        tab("Settings")
        shot("settings-1")
        for i in 2...4 { app.swipeUp(velocity: .slow); shot("settings-\(i)") }
    }

    func testCaptureStoreScreens() {
        app.launch()
        sleep(2)
        shot("store-01-home")

        tap("Start scan")
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 20))
        // Second scan so the "since your last scan" card appears.
        app.buttons["Scan again"].tap()
        sleep(5)
        shot("store-02-results")

        app.swipeUp(velocity: .slow)
        sleep(1)
        shot("store-03-clues")

        let clue = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Last restart'")).firstMatch
        scrollTo(clue)
        if clue.exists { clue.tap(); sleep(2); shot("store-04-finding") }
        app.navigationBars.buttons.element(boundBy: 0).tap()

        tab("Sensitive apps")
        sleep(1)
        for name in ["Dating and LGBTQ+", "Health and fertility", "VPN, Tor and censorship tools"] {
            let row = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
            scrollTo(row, max: 4)
            if row.exists { row.tap() }
        }
        app.swipeDown(velocity: .fast)
        sleep(1)
        shot("store-05-sensitive")

        tab("Check-up")
        sleep(1)
        shot("store-06-checkup")

        tab("Scan")
        let board = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Privacy scoreboard'")).firstMatch
        scrollTo(board, max: 14)
        if board.exists { board.tap(); sleep(2); shot("store-07-scoreboard") }
    }
}
