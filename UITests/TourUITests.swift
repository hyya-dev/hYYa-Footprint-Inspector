// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest

/// Opens every page and sub-page the way a person would and photographs each one top to bottom
/// (`tour-NN-…`), upright and sideways, for a person to look through before any build goes to
/// TestFlight (owner, 2026-10-28). Sample data only, on Simulators.
final class TourUITests: XCTestCase {
    private var app: XCUIApplication!
    private var n = 0

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-sampleData"]
        XCUIDevice.shared.orientation = .portrait
    }

    func testTourUpright() { tour() }

    /// Sideways on a small phone the scan must start from its button.
    func testSidewaysScanStarts() {
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        tab("Footprint")
        let start = app.buttons["Start with check 1"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5), "no start button")
        shot("sideways-start-before")
        XCTAssertTrue(start.isHittable, "start button not hittable: \(start.frame)")
        start.tap()
        let done = app.buttons["Scan again"].waitForExistence(timeout: 25)
        shot("sideways-start-after")
        XCTAssertTrue(done, "scan didn't start or finish")
        XCUIDevice.shared.orientation = .portrait
    }
    func testTourSideways() { tour(sideways: true) }

    @discardableResult
    /// Settings is the Score page's last row: the system tab bar holds Score and the four checks.
    private func openSettings() {
        app.buttons["Score"].firstMatch.tap()
        sleep(1)
        let row = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Settings'")).firstMatch
        var i = 0
        while !(row.exists && row.isHittable) && i < 14 { app.swipeUp(velocity: .slow); i += 1 }
        row.tap()
        sleep(1)
    }

    private func shot(_ name: String) -> Data {
        sleep(1)
        n += 1
        let image = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: image)
        a.name = String(format: "tour-%02d-%@", n, name)
        a.lifetime = .keepAlways
        add(a)
        return image.pngRepresentation
    }

    /// The whole page, a screen at a time, then back to the top.
    /// Stops when a swipe no longer moves anything: the screen looks the same as before it.
    private func page(_ name: String, screens: Int = 6) {
        var last = shot(name)
        for i in 2...max(2, screens) {
            app.swipeUp(velocity: .slow)
            sleep(1)
            if XCUIScreen.main.screenshot().pngRepresentation == last { break }
            last = shot("\(name)-\(i)")
        }
        for _ in 0..<screens { app.swipeDown(velocity: .fast) }
    }

    /// Closes a sheet with its own button when it has one, else by swiping it down.
    private func closeSheet(_ label: String) {
        let b = app.buttons[label].firstMatch
        if b.waitForExistence(timeout: 3) && b.isHittable { b.tap() } else { app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast) }
        sleep(1)
    }

    private func tab(_ name: String) {
        app.buttons[name].firstMatch.tap()
        sleep(1)
    }

    private func back() {
        let bar = app.navigationBars.buttons.element(boundBy: 0)
        if bar.exists { bar.tap() } else if app.buttons["BackButton"].exists { app.buttons["BackButton"].firstMatch.tap() }
        sleep(1)
    }

    private func find(_ predicate: String, _ arg: String, scrolls: Int = 14) -> XCUIElement {
        let el = app.buttons.containing(NSPredicate(format: predicate, arg)).firstMatch
        var i = 0
        while !(el.exists && el.isHittable) && i < scrolls { app.swipeUp(velocity: .slow); i += 1 }
        return el
    }

    private func tour(sideways: Bool = false) {
        app.launch()
        if sideways { XCUIDevice.shared.orientation = .landscapeLeft }
        sleep(2)

        page("score-before-scan")
        tab("Footprint")
        page("footprint-start", screens: 2)
        app.buttons["Start with check 1"].firstMatch.tap()
        _ = app.buttons["Scan again"].waitForExistence(timeout: 25)
        page("footprint-results", screens: 10)

        let finding = find("label CONTAINS %@", "last restart")
        if finding.exists { finding.tap(); sleep(1); page("finding", screens: 4); back() }
        for _ in 0..<12 { app.swipeDown(velocity: .fast) }
        let section = find("label BEGINSWITH %@", "Device identity")
        if section.exists { section.tap(); sleep(1); page("section", screens: 3); back() }
        for _ in 0..<12 { app.swipeDown(velocity: .fast) }

        let how = find("label == %@", "How the score works")
        if how.exists { how.tap(); sleep(1); page("how-score-works", screens: 3); closeSheet("Done") }
        let fix = find("label == %@", "Fix them with me")
        if fix.exists {
            fix.tap(); sleep(3); shot("fix-1")
            while app.buttons["Done, next"].exists { app.buttons["Done, next"].tap(); sleep(1) }
            shot("fix-finished")
            closeSheet("See my new score"); sleep(1)
        }

        tab("Score")
        page("score-after-scan", screens: 4)

        tab("Sensitive")
        page("sensitive", screens: 4)
        let check = find("label BEGINSWITH %@", "Check ")
        if check.exists { check.tap(); sleep(2); page("sensitive-result", screens: 4) }

        tab("Tracker")
        page("tracker", screens: 8)

        tab("Check-up")
        page("checkup", screens: 6)
        for step in ["Restart once a week", "Check for leaked passwords", "Safety Check"] {
            for _ in 0..<12 { app.swipeDown(velocity: .fast) }
            let row = find("label CONTAINS %@", step)
            if row.exists { row.tap(); sleep(1); page("checkup-\(step)", screens: 3); back() }
        }

        openSettings()
        page("settings", screens: 6)
        for row in ["Scan history", "Privacy scoreboard"] {
            for _ in 0..<12 { app.swipeDown(velocity: .fast) }
            let r = find("label BEGINSWITH %@", row)
            if r.exists { r.tap(); sleep(1); page(row, screens: 3); back() }
        }
        XCUIDevice.shared.orientation = .portrait
    }
}
