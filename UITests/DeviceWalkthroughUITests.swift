// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest

/// On-device walkthrough: scan, every permission category, and every Settings link in the Lab.
/// Results are printed as `RESULT|…` lines and every screen is attached as a screenshot.
/// It never runs the Sensitive apps check.
@MainActor
final class DeviceWalkthroughUITests: XCTestCase {
    let app = XCUIApplication()
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")

    override func setUp() async throws {
        continueAfterFailure = true
    }

    // MARK: Helpers

    func shot(_ name: String, _ source: XCUIScreenshotProviding? = nil) {
        let screenshot = (source ?? XCUIScreen.main).screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func log(_ line: String) {
        print("RESULT|\(line)")
        let a = XCTAttachment(string: line)
        a.name = "log-\(line.prefix(40))"
        a.lifetime = .keepAlways
        add(a)
    }

    /// Taps the best "allow" button on any system alert. Returns the label tapped, if any.
    @discardableResult
    func handleSystemAlert(context: String) -> String? {
        let preferred = ["Allow Full Access", "Allow While Using App", "Allow Access to All Photos",
                         "Allow", "OK", "Continue"]
        for container in [springboard, app] {
            let alert = container.alerts.firstMatch
            guard alert.exists else { continue }
            let labels = alert.buttons.allElementsBoundByIndex.map(\.label)
            shot("\(context)-alert")
            log("\(context)|alert|buttons=\(labels.joined(separator: " / "))")
            for wanted in preferred {
                if let label = labels.first(where: { $0 == wanted }) {
                    alert.buttons[label].tap()
                    return label
                }
            }
            if let share = labels.first(where: { $0.hasPrefix("Share All") }) {
                alert.buttons[share].tap()
                return share
            }
            return nil
        }
        // Contacts' second step can be a sheet rather than an alert.
        for container in [springboard, app] {
            let share = container.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Share All'")).firstMatch
            if share.exists {
                shot("\(context)-share-sheet")
                let label = share.label
                share.tap()
                return label
            }
        }
        return nil
    }

    func launchAndScan() -> String {
        app.launch()
        handleSystemAlert(context: "launch")
        let start = app.buttons["Start with check 1"]
        let again = app.buttons["Scan again"]
        XCTAssertTrue(start.waitForExistence(timeout: 15), "Start scan button missing")
        let t0 = Date()
        start.tap()
        if !again.waitForExistence(timeout: 2), start.exists, start.isEnabled {
            start.tap()   // first tap right after launch is sometimes swallowed
        }
        var found = false
        while Date().timeIntervalSince(t0) < 40 {
            handleSystemAlert(context: "scan")
            if again.exists { found = true; break }
            usleep(250_000)
        }
        let elapsed = Date().timeIntervalSince(t0)
        let score = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH 'Footprint score'")).firstMatch
        let scoreText = score.exists ? score.label : "score not found"
        log("scan|finished=\(found)|seconds=\(String(format: "%.1f", elapsed))|\(scoreText)")
        return scoreText
    }

    // MARK: 1. Scan screen

    func test1_ScanScreen() {
        _ = launchAndScan()
        shot("scan-00-top")
        let end = app.buttons.matching(NSPredicate(format: "label CONTAINS 'scan history'")).firstMatch
        for i in 1...20 {
            app.swipeUp()
            usleep(400_000)
            shot(String(format: "scan-%02d", i))
            if end.exists && end.isHittable { break }
        }
        // Concerning ("Worth a look") rows, read as text for the report.
        let rows = app.staticTexts.allElementsBoundByIndex.prefix(80).map(\.label)
        log("scan|visibleTextsAtEnd=\(rows.count)")
    }

    // MARK: 2. Permission categories

    static let categories: [(String, [String])] = [
        ("Motion & Fitness", ["What you're doing", "Steps, distance and floors", "Air pressure and altitude"]),
        ("Location", ["Where you are", "Altitude and floor", "Speed and direction", "Precise Location"]),
        ("Camera", ["Your cameras"]),
        ("Bluetooth", ["Nearby devices"]),
        ("Local Network", ["Devices on your Wi-Fi"]),
        ("Contacts", ["Size of your address book", "Relationship labels", "Contact accounts"]),
        ("Photos", ["Places in your photos", "Likely home and work", "Library size"]),
        ("Calendars", ["Calendar accounts", "How busy you are"]),
        ("Reminders", ["Reminder lists", "Open reminders"]),
        ("Media & Apple Music", ["Library size", "Your taste", "Apple Music subscription"]),
    ]

    func openCategory(_ title: String) -> Bool {
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        for _ in 0..<15 {
            if row.exists && row.isHittable { row.tap(); return true }
            app.swipeUp()
        }
        return false
    }

    func test2_PermissionCategories() {
        _ = launchAndScan()
        for (title, readingTitles) in Self.categories {
            let ctx = "perm-\(title.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "&", with: ""))"
            guard openCategory(title) else {
                log("\(ctx)|row not found"); shot("\(ctx)-notfound"); continue
            }
            usleep(500_000)
            shot("\(ctx)-0-before")
            let showMe = app.buttons["Show me"]
            var tappedShow = false
            if showMe.waitForExistence(timeout: 2) { showMe.tap(); tappedShow = true }
            let t0 = Date()
            var alertTapped: [String] = []
            var outcome = "timeout"
            let preview = app.staticTexts.matching(NSPredicate(format: "label ==[c] 'What an app with this permission gets'")).firstMatch
            while Date().timeIntervalSince(t0) < 45 {
                if let tapped = handleSystemAlert(context: ctx) { alertTapped.append(tapped) }
                if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'You said no'")).firstMatch.exists {
                    outcome = "denied"; break
                }
                if app.staticTexts["This isn't available on this device."].exists { outcome = "unavailable"; break }
                if !preview.exists {
                    let present = readingTitles.filter { app.staticTexts[$0].exists }
                    if !present.isEmpty { outcome = "readings(\(present.count)/\(readingTitles.count))"; break }
                }
                usleep(200_000)
            }
            let secs = Date().timeIntervalSince(t0)
            // Let slow scanners (Bluetooth, LAN) fill in a bit more before the screenshot.
            usleep(outcome.hasPrefix("readings") ? 1_500_000 : 0)
            let present = readingTitles.filter { app.staticTexts[$0].exists }
            log("\(ctx)|showMe=\(tappedShow)|alerts=\(alertTapped.joined(separator: ","))|outcome=\(outcome)|seconds=\(String(format: "%.1f", secs))|rowsAfter=\(present.count)/\(readingTitles.count)")
            shot("\(ctx)-1-after")
            if app.cells.count > 3 { app.swipeUp(); usleep(300_000); shot("\(ctx)-2-after-scrolled") }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            if back.exists { back.tap() }
            usleep(600_000)
        }
        shot("perm-scan-list-end")
    }

    // MARK: 3. Settings links

    func test3_SettingsLinks() {
        app.launch()
        handleSystemAlert(context: "lab-launch")
        // The lab lives in Settings › Developer (Debug builds only) since 2026-10-17.
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "Settings tab missing")
        settingsTab.tap()
        let lab = app.buttons["Settings link lab"]
        for _ in 0..<8 where !lab.isHittable { app.swipeUp() }
        lab.tap()
        XCTAssertTrue(app.navigationBars["Settings link lab"].waitForExistence(timeout: 5))
        shot("lab-00-list")

        // Collect row labels by scrolling.
        var ids: [String] = []
        for pass in 0..<6 {
            for cell in app.buttons.allElementsBoundByIndex where cell.label.contains(":") || cell.label.contains("prefs") {
                let label = cell.label
                if !ids.contains(label) { ids.append(label) }
            }
            if pass < 5 { app.swipeUp() }
        }
        log("lab|rows=\(ids.count)")
        // Back to top.
        for _ in 0..<6 { app.swipeDown() }

        for (index, label) in ids.enumerated() {
            settings.terminate()
            app.activate()
            usleep(500_000)
            let row = app.buttons[label]
            var tries = 0
            while !(row.exists && row.isHittable) && tries < 12 { app.swipeUp(); tries += 1 }
            if !(row.exists && row.isHittable) {
                for _ in 0..<12 where !(row.exists && row.isHittable) { app.swipeDown() }
            }
            guard row.exists && row.isHittable else { log("link|\(label)|row not hittable"); continue }
            row.tap()
            let opened = settings.wait(for: .runningForeground, timeout: 6)
            var landed = "nothing (Settings did not come to front)"
            if opened {
                sleep(2)
                let navTitles = settings.navigationBars.allElementsBoundByIndex.map { $0.identifier }
                let texts = settings.staticTexts.allElementsBoundByIndex.prefix(8).map(\.label)
                landed = "nav=\(navTitles.joined(separator: ","))|texts=\(texts.joined(separator: " ; "))"
                shot(String(format: "link-%02d", index + 1), settings)
            } else {
                usleep(800_000)
                shot(String(format: "link-%02d-noSettings", index + 1))
                if let tapped = handleSystemAlert(context: "link-\(index + 1)") { landed += "|alert tapped \(tapped)" }
            }
            log("link|\(label)|\(landed)")
            app.activate()
            _ = app.wait(for: .runningForeground, timeout: 5)
        }
        app.activate()
        shot("lab-99-results")
        app.swipeUp()
        shot("lab-99-results-2")
        settings.terminate()
    }
    // MARK: 4. Extra link variants (opened by the test runner, not by the app)

    /// Checks why most `App-prefs:` links land on the Apps list, and whether a warm Settings
    /// behaves differently from a cold one.
    func test4_SettingsLinkVariants() {
        let variants = [
            "App-prefs:Privacy", "App-prefs:Bluetooth", "App-prefs:root=Bluetooth",
            "App-prefs:root=Privacy&path=LOCATION", "App-prefs:com.apple.mobilesafari",
            "App-prefs:com.hyya.footprintinspector", "App-prefs:com.apple.Preferences",
            "App-prefs:WIFI",
            // settings-navigation:// and prefs:root= are rejected by iOS (LSApplicationWorkspace error 115).
        ]
        for (index, string) in variants.enumerated() {
            for warm in [false, true] {
                settings.terminate()
                if warm { settings.activate(); _ = settings.wait(for: .runningForeground, timeout: 6); sleep(1) }
                let before = settings.state.rawValue
                guard let url = URL(string: string) else { continue }
                XCUIDevice.shared.system.open(url)
                sleep(1)
                let springAlert = springboard.alerts.firstMatch
                var note = ""
                if springAlert.exists {
                    let labels = springAlert.buttons.allElementsBoundByIndex.map { $0.label }
                    note = "|confirm=\(labels.joined(separator: "/"))"
                    if let open = labels.first(where: { $0 == "Open" }) { springAlert.buttons[open].tap() }
                }
                let opened = settings.wait(for: .runningForeground, timeout: 6)
                sleep(2)
                let nav = settings.navigationBars.allElementsBoundByIndex.map { $0.identifier }
                let tag = warm ? "warm" : "cold"
                if opened { shot(String(format: "variant-%02d-%@", index + 1, tag), settings) }
                log("variant|\(string)|\(tag)|stateBefore=\(before)|opened=\(opened)|nav=\(nav.joined(separator: ","))\(note)")
            }
        }
        settings.terminate()
    }
}
