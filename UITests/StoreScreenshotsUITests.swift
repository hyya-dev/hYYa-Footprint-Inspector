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
    /// Candidate screens for a stronger slide, attached as `cand-…`. Grants permissions when asked.
    func testCaptureCandidates() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        app.launch()
        sleep(2)
        tap("Start scan")
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 20))
        for group in ["Remembered after deleting", "Location", "Photos", "Contacts", "Web fingerprint", "Account and App Store"] {
            app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast)
            let row = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", group)).firstMatch
            scrollTo(row, max: 16)
            guard row.exists else { continue }
            row.tap()
            sleep(1)
            let show = app.buttons["Show me"].firstMatch
            if show.waitForExistence(timeout: 2) {
                show.tap()
                for label in ["Allow While Using App", "Allow Full Access", "Allow", "Continue", "OK"] {
                    let b = springboard.buttons[label]
                    if b.waitForExistence(timeout: 3) { b.tap(); sleep(1) }
                }
                sleep(4)
            }
            shot("cand-\(group)")
            app.swipeUp(velocity: .slow)
            shot("cand-\(group)-2")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
    }

    /// Screens changed in the plain-language pass, attached as `review-…`.
    func testCaptureReview() {
        app.launch()
        sleep(2)
        tap("Start scan")
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 20))
        for group in ["Device identity", "Motion sensors", "Graphics and mobile network"] {
            app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast)
            let row = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", group)).firstMatch
            scrollTo(row, max: 16)
            guard row.exists else { continue }
            row.tap(); sleep(1)
            shot("review-\(group)")
            app.navigationBars.buttons.element(boundBy: 0).tap(); sleep(1)
        }
        tab("Sensitive apps"); sleep(1)
        app.swipeUp(velocity: .fast); app.swipeUp(velocity: .fast); sleep(1)
        shot("review-sensitive-bottom")
        app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Check'")).firstMatch.tap()
        sleep(2)
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); sleep(1)
        shot("review-sensitive-result")
    }

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
        sleep(1)
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 20))
        sleep(2)
        shot("store-02-results")

        // The "Worth a look" list, with the comparison card's top edge just below the status bar,
        // so nothing sits half-hidden under the clock.
        let card = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'since your last scan'")).firstMatch
        if card.waitForExistence(timeout: 3) {
            let top = app.windows.firstMatch.frame.minY + 66
            let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: card.frame.midX, dy: top + 34))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.8)
        }
        sleep(2)
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
            if row.exists && !row.isSelected { row.tap() }
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
