// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest

/// Leaving the app to change a setting, then coming back, must land on the same page and the same
/// open card (owner, 2026-10-28: it came back to the Score page instead).
final class ReturnUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        // A clean start each time; scans are kept so they're still there after the quit.
        app.launchArguments = ["-sampleData", "-keepScans"]
        XCUIDevice.shared.orientation = .portrait
    }

    private func leaveAndComeBack(_ what: String) {
        XCUIDevice.shared.press(.home)
        sleep(3)
        app.activate()
        sleep(3)
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = "back-\(what)"; a.lifetime = .keepAlways; add(a)
    }

    private func scrollTo(_ el: XCUIElement) {
        var i = 0
        while !(el.exists && el.isHittable) && i < 12 { app.swipeUp(velocity: .slow); i += 1 }
    }

    func testCheckUpStepSurvives() {
        app.launch()
        app.buttons["Check-up"].firstMatch.tap()
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Safety Check'")).firstMatch
        scrollTo(row)
        row.tap()
        XCTAssertTrue(app.staticTexts["Where to go"].waitForExistence(timeout: 5), "step didn't open")
        leaveAndComeBack("checkup-step")
        XCTAssertTrue(app.staticTexts["Where to go"].exists, "came back without the Check-up step open")
        XCTAssertTrue(app.buttons["Check-up"].firstMatch.isSelected, "came back on another page")
    }

    func testFixWalkThroughSurvives() {
        app.launchArguments += ["-autoScan"]
        app.launch()
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 25))
        let fix = app.buttons["Fix them with me"]
        scrollTo(fix)
        fix.tap()
        XCTAssertTrue(app.buttons["Done, next"].waitForExistence(timeout: 5), "walk-through didn't open")
        leaveAndComeBack("fix")
        XCTAssertTrue(app.buttons["Done, next"].exists, "came back without the walk-through open")
    }

    func testFindingSurvives() {
        app.launchArguments += ["-autoScan"]
        app.launch()
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 25))
        let clue = app.buttons.containing(NSPredicate(format: "label CONTAINS 'last restart'")).firstMatch
        scrollTo(clue)
        clue.tap()
        XCTAssertTrue(app.staticTexts["More about this"].waitForExistence(timeout: 5) || app.buttons["More about this"].waitForExistence(timeout: 2), "finding didn't open")
        leaveAndComeBack("finding")
        XCTAssertTrue(app.staticTexts["More about this"].exists || app.buttons["More about this"].exists, "came back without the finding open")
    }

    /// iOS often quits the app while the person is in Settings. Reopened, it must be where it was.
    private func quitInBackgroundAndReopen(_ what: String) {
        XCUIDevice.shared.press(.home)
        sleep(4)
        app.terminate()
        sleep(2)
        app.launchArguments = ["-sampleData", "-keepPlace"]
        app.launch()
        sleep(5)
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = "reopened-\(what)"; a.lifetime = .keepAlways; add(a)
    }

    func testCheckUpStepSurvivesBeingQuit() {
        app.launch()
        app.buttons["Check-up"].firstMatch.tap()
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Safety Check'")).firstMatch
        scrollTo(row)
        row.tap()
        XCTAssertTrue(app.staticTexts["Where to go"].waitForExistence(timeout: 5), "step didn't open")
        quitInBackgroundAndReopen("checkup-step")
        XCTAssertTrue(app.staticTexts["Where to go"].waitForExistence(timeout: 5), "reopened without the Check-up step")
    }

    func testFixWalkThroughSurvivesBeingQuit() {
        app.launch()
        app.buttons["Footprint"].firstMatch.tap()
        let start = app.buttons["Start with check 1"]
        if start.waitForExistence(timeout: 4) { start.tap() }
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 25))
        let fix = app.buttons["Fix them with me"]
        scrollTo(fix)
        fix.tap()
        XCTAssertTrue(app.buttons["Done, next"].waitForExistence(timeout: 5), "walk-through didn't open")
        quitInBackgroundAndReopen("fix")
        XCTAssertTrue(app.buttons["Done, next"].waitForExistence(timeout: 15), "reopened without the walk-through")
    }
}
