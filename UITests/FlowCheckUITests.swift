// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest

/// Walks every main flow the way a person would and checks that, after each tap, what they need
/// to see is on screen without scrolling. Each step is attached as a screenshot (`flow-NN-…`) for
/// review. Run on a Simulator with sample data, never on a real phone.
final class FlowCheckUITests: XCTestCase {
    private var app: XCUIApplication!
    private var n = 0

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-sampleData"]
        // A test that stopped sideways must not leave the next one sideways.
        XCUIDevice.shared.orientation = .portrait
    }

    private func shot(_ name: String) {
        n += 1
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = String(format: "flow-%02d-%@", n, name)
        a.lifetime = .keepAlways
        add(a)
    }

    /// On screen now, inside the window and not hidden under the tab bar.
    private func assertVisible(_ el: XCUIElement, _ what: String, timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) {
        guard el.waitForExistence(timeout: timeout) else { XCTFail("\(what): not found", file: file, line: line); return }
        let window = app.windows.firstMatch.frame
        // Upright, the app's own navbar runs along the bottom; nothing may hide under it.
        let bar = app.otherElements["navbar"].firstMatch
        let tabBarTop = bar.exists && bar.frame.minY > window.midY ? bar.frame.minY : window.maxY
        let f = el.frame
        XCTAssertTrue(f.minY >= window.minY && f.minY < tabBarTop - 20,
                      "\(what): off screen (top at \(Int(f.minY)), visible area \(Int(window.minY))–\(Int(tabBarTop)))", file: file, line: line)
    }

    private func text(_ s: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", s)).firstMatch
    }

    private func tab(_ name: String) {
        let b = app.tabBars.buttons[name]
        if b.exists { b.tap() } else { app.buttons[name].firstMatch.tap() }
        sleep(1)
    }

    /// Short drags until the element is fully on screen; a swipe can overshoot on a short screen
    /// held sideways and leave it half off the top.
    private func scrollUntil(_ el: XCUIElement, max: Int = 16) {
        var i = 0
        func onScreen() -> Bool {
            guard el.exists else { return false }
            let w = app.windows.firstMatch.frame, f = el.frame
            return f.minY >= w.minY && f.maxY <= w.maxY - 20
        }
        while !onScreen() && i < max {
            let w = app.windows.firstMatch
            let from = w.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.75))
            from.press(forDuration: 0.05, thenDragTo: w.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)))
            i += 1
        }
    }

    /// Upright the navbar runs along the bottom with all six pages fully on screen, and the
    /// Score page has no Settings button at its top (owner, 2026-10-28).
    func testNavbarUpright() {
        app.launch()
        let bar = app.otherElements["navbar"].firstMatch
        let w = app.windows.firstMatch.frame
        XCTAssertTrue(bar.waitForExistence(timeout: 8), "no navbar")
        // At the bottom, or on the folded iPhone Duo down the right in the status strip's column.
        let atBottom = bar.frame.minY > w.midY, atRight = bar.frame.minX > w.midX
        XCTAssertTrue(atBottom || atRight, "navbar is neither at the bottom nor on the right")
        for name in ["Score", "Footprint", "Sensitive apps", "Tracker", "Check-up", "Settings"] {
            let b = app.buttons[name].firstMatch
            XCTAssertTrue(b.exists && b.frame.minX >= w.minX && b.frame.maxX <= w.maxX && b.frame.minY >= w.minY && b.frame.maxY <= w.maxY,
                          "\(name) missing or cut off in the navbar")
        }
        XCTAssertEqual(app.buttons.matching(identifier: "Settings").count, 1, "a second Settings button is on the page")
        shot("navbar-upright")
    }

    func testFootprintFlow() {
        app.launch()
        tab("Footprint")
        let start = app.buttons["Start with check 1"]
        assertVisible(start, "Start with check 1")
        shot("footprint-start")
        start.tap()
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 25), "scan didn't finish")
        XCTAssertFalse(app.buttons["Share my result"].exists, "Share belongs on the Score page only")
        shot("footprint-result")
        tab("Score")
        assertVisible(text("checks"), "overall score line")
        assertVisible(app.buttons["Share my result"].firstMatch, "Share my result")
        shot("score-page")
        tab("Footprint")

        let fix = app.buttons["Fix them with me"]
        scrollUntil(fix)
        if fix.exists {
            fix.tap()
            assertVisible(app.buttons["Done, next"], "first fix step")
            shot("fix-step-1")
            app.buttons["Done, next"].tap()
            sleep(1)
            shot("fix-step-2")
        }
    }

    // MARK: Every close and done button, tapped (never swiped), upright and sideways.

    /// Taps a sheet's own button and checks that something only that sheet shows has gone.
    private func assertClosesByTapping(_ button: XCUIElement, unique: XCUIElement, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(unique.waitForExistence(timeout: 8), "\(what): sheet didn't open", file: file, line: line)
        XCTAssertTrue(button.waitForExistence(timeout: 5) && button.isHittable, "\(what): button not tappable", file: file, line: line)
        shot("\(what)-open")
        button.tap()
        let gone = NSPredicate(format: "exists == false")
        XCTAssertEqual(XCTWaiter().wait(for: [expectation(for: gone, evaluatedWith: unique)], timeout: 5), .completed,
                       "\(what): still open after tapping its button", file: file, line: line)
    }

    private func closeButtonsChecked(_ orientation: UIDeviceOrientation, _ tag: String) {
        app.launchArguments += ["-autoScan"]
        app.launch()
        XCUIDevice.shared.orientation = orientation
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 25), "scan didn't finish")

        // How the score works: Done.
        let how = app.buttons["How the score works"]
        scrollUntil(how)
        how.tap()
        assertClosesByTapping(app.buttons["Done"].firstMatch, unique: text("The footprint score in detail"), "how-\(tag)")

        // Fix them with me: Close.
        let fix = app.buttons["Fix them with me"]
        scrollUntil(fix)
        if fix.exists {
            fix.tap()
            assertClosesByTapping(app.buttons["Close"].firstMatch, unique: app.buttons["Done, next"], "fix-\(tag)")
        }
        XCUIDevice.shared.orientation = .portrait
    }

    /// Every page sideways, photographed for review (captures come out rotated).
    func testPagesSideways() {
        app.launchArguments += ["-autoScan"]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["Scan again"].waitForExistence(timeout: 25), "scan didn't finish")
        shot("sideways-footprint")
        // Sideways the navbar runs down the left edge (owner, 2026-10-28), all six pages on screen.
        let rail = app.otherElements["navbar"].firstMatch
        XCTAssertTrue(rail.waitForExistence(timeout: 5) && rail.frame.maxX < app.windows.firstMatch.frame.midX, "navbar isn't on the left")
        for name in ["Score", "Footprint", "Sensitive apps", "Tracker", "Check-up", "Settings"] {
            let b = app.buttons[name].firstMatch
            XCTAssertTrue(b.exists && b.frame.minY >= 0 && b.frame.maxY <= app.windows.firstMatch.frame.maxY, "\(name) cut off in the navbar")
        }
        for name in ["Score", "Sensitive apps", "Tracker", "Check-up", "Settings"] {
            tab(name)
            shot("sideways-\(name)")
        }
        XCUIDevice.shared.orientation = .portrait
    }

    /// Dynamic Type (1.0.2): at the largest accessibility text size nothing on any page runs off
    /// the screen's edge.
    func testNothingClippedAtLargestText() {
        for tab in ["home", "footprint", "sensitive", "tracker", "checkup", "settings"] {
            app.terminate()
            app.launchArguments = ["-sampleData", "-autoScan", "-startTab", tab,
                                   "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            app.launch()
            sleep(8)
            let w = app.windows.firstMatch.frame
            let clipped = (app.staticTexts.allElementsBoundByIndex + app.buttons.allElementsBoundByIndex)
                .filter { $0.frame.width > 0 && $0.frame.minX < w.minX - 1 }
            XCTAssertTrue(clipped.isEmpty, "\(tab): \(clipped.count) items run off the left edge, e.g. \(clipped.first?.label.prefix(40) ?? "")")
            if tab == "footprint" { shot("largest-text-footprint") }
        }
    }

    func testCloseButtonsUpright() { closeButtonsChecked(.portrait, "upright") }
    func testCloseButtonsSideways() { closeButtonsChecked(.landscapeLeft, "sideways") }

    func testSensitiveFlow() {
        app.launchArguments += ["-sensitiveCategories", "dating,health,circumvention"]
        app.launch()
        tab("Sensitive apps")
        assertVisible(text("Which apps give you away"), "Sensitive title")
        shot("sensitive-start")
        let check = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Check '")).firstMatch
        scrollUntil(check)
        check.tap()
        sleep(1)
        // The result must be the first thing seen, not the bottom of the page.
        let hidden = text("Hidden for your privacy")
        let none = text("None of these apps answered")
        let shown = hidden.waitForExistence(timeout: 5) ? hidden : none
        assertVisible(shown, "Sensitive result after Check")
        shot("sensitive-result")
        if hidden.exists {
            app.buttons["Show the apps"].tap()
            sleep(1)
            assertVisible(text("Any app can see you have"), "first revealed app")
            shot("sensitive-revealed")
        }
    }

    func testTrackerFlow() {
        app.launch()
        tab("Tracker")
        assertVisible(text("In short"), "Tracker summary with sample report")
        shot("tracker-result")
        let worth = text("Shares with ad or analytics companies")
        scrollUntil(worth)
        shot("tracker-worth")
    }

    func testCheckUpFlow() {
        app.launch()
        tab("Check-up")
        assertVisible(text("checked"), "Check-up heading")
        let first = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Safety Check'")).firstMatch
        assertVisible(first, "first Check-up row without scrolling")
        shot("checkup-list")
        first.tap()
        assertVisible(text("Where to go"), "step page")
        shot("checkup-step")
        // Left ticked by an earlier run: untick so the test starts from the same place.
        let ticked = app.buttons["Checked ✓"]
        if ticked.waitForExistence(timeout: 2) { scrollUntil(ticked); ticked.tap(); sleep(1) }
        let done = app.buttons["I've checked this"]
        scrollUntil(done)
        done.tap()
        sleep(1)
        // A recent restart is ticked by itself, so one or two areas are ticked now.
        let ticked1 = text("1 of"), ticked2 = text("2 of")
        assertVisible(ticked1.waitForExistence(timeout: 3) ? ticked1 : ticked2, "back on the list with the area ticked")
        shot("checkup-after")
    }

    func testSettingsFlow() {
        app.launch()
        tab("Settings")
        assertVisible(app.buttons["Rate the App"].firstMatch, "rating card")
        let reminder = text("Re-scan reminder")
        scrollUntil(reminder)
        shot("settings-reminder")
        let more = text("Visit hyya.com")
        scrollUntil(more)
        shot("settings-more")
    }
}
