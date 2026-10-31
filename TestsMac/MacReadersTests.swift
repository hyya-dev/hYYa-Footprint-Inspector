// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest
@testable import FootprintInspector

/// Runs every Mac reader on this Mac and checks the catalogue covers what they return.
@MainActor
final class MacReadersTests: XCTestCase {
    /// On a Mac any local program can pass launch arguments. They must not fake the install record.
    func testLaunchArgumentsCantFakeTheInstallRecord() {
        let key = ReinstallSource.recordedKey
        let defaults = UserDefaults.standard
        let args = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        let before = defaults.object(forKey: key)
        defer {
            defaults.setVolatileDomain(args, forName: UserDefaults.argumentDomain)
            defaults.set(before, forKey: key)
        }
        defaults.set(true, forKey: key)
        defaults.setVolatileDomain([key: false], forName: UserDefaults.argumentDomain)
        XCTAssertFalse(defaults.bool(forKey: key))
        XCTAssertTrue(ReinstallSource.alreadyRecorded)
    }

    override func setUp() {
        // Every test starts as a fresh install would: nothing recorded yet.
        UserDefaults.standard.removeObject(forKey: ReinstallSource.recordedKey)
    }

    func testEveryReadingHasADefinitionAndEveryDefinitionIsRead() async {
        var ids: Set<String> = []
        for source in MacSources.all {
            for reading in await source.read() {
                XCTAssertNotNil(SignalCatalogue.definition(reading.id), "No definition for reading \(reading.id)")
                XCTAssertFalse(reading.value.isEmpty, "Empty value for \(reading.id)")
                ids.insert(reading.id)
                print("READING \(reading.id) = \(reading.value.prefix(60)) [\(reading.items.count) items]")
            }
        }
        let passive = SignalCatalogue.list.filter { $0.section.group != .permission }.map(\.id)
        let unread = passive.filter { !ids.contains($0) && !["mac-battery", "first-download", "storefront"].contains($0) }
        XCTAssertTrue(unread.isEmpty, "Defined but never read: \(unread)")
    }

    func testEveryMacSectionHasDefinitions() {
        for section in SignalSection.onThisPlatform {
            XCTAssertFalse(SignalCatalogue.definitions(in: section).isEmpty, "Section \(section) has nothing to show")
        }
    }

    func testSettingsFixesCarryAPane() {
        for d in SignalCatalogue.list where d.fix.level == .openSettings {
            XCTAssertNotNil(d.fix.settingsPane, "\(d.id) says Open in System Settings but has no page")
        }
    }

    func testNoDeviceWordsInMacCopy() {
        for d in SignalCatalogue.list {
            let text = [d.title, d.reveals, d.why, d.fix.summary] + d.fix.steps
            for line in text {
                XCTAssertNil(line.range(of: #"\b(iPhone|iPad|iOS)\b"#, options: .regularExpression), "\(d.id): \(line)")
            }
        }
    }

    /// The install list must live in the device-only (data protection) keychain on a Mac, where
    /// ThisDeviceOnly applies, not the login keychain that backups and Migration Assistant carry.
    func testInstallListIsInTheDeviceOnlyKeychain() async {
        let readings = await ReinstallSource().read()
        XCTAssertTrue(readings.contains { $0.id == "reinstall-memory" && $0.value.contains("Installed") })
        var found: CFTypeRef?
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: "dates",
                                    kSecUseDataProtectionKeychain as String: true,
                                    kSecReturnAttributes as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        XCTAssertEqual(SecItemCopyMatching(query as CFDictionary, &found), errSecSuccess,
                       "Install list not found in the data protection keychain")
    }
}

/// Every Mac finding has a plain headline and one short line (1.0.1).
final class MacPlainWordsTests: XCTestCase {
    func testEveryMacFindingHasPlainWords() {
        for d in MacSignalCatalogue.list {
            let entry = PlainWords.text[d.id]
            XCTAssertNotNil(entry, "No plain words for \(d.id)")
            if let entry { XCTAssertLessThanOrEqual(entry.headline.count, 60, "Headline too long: \(d.id)") }
        }
    }
}

/// Owner's Mac test, 2026-10-28.
@MainActor
final class MacLiveScoreTests: XCTestCase {
    /// Tracker counts on a Mac once every place is ticked, and never before.
    func testTrackerCountsOnceEveryPlaceIsChecked() {
        let partway = OverallScore.current(scanner: Scanner(history: HistoryStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))),
                                           history: HistoryStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)),
                                           check: PrivacyCheck(fileURL: nil), checkUpStored: "", trackerStored: "screen,files")
        XCTAssertNil(partway.parts[.tracker])
        let all = OverallScore(footprint: 44, sensitiveFound: nil, trackerSharing: nil, trackerReviewed: true, checkUpDone: 0, checkUpTotal: 17)
        XCTAssertEqual(all.parts[.tracker], 100)
        XCTAssertEqual(all.total, 4)
    }

    /// A private Wi-Fi address has the locally administered bit set.
    func testPrivateWiFiAddressIsRecognised() {
        XCTAssertTrue(MacNetworkSource.isPrivate("Wi-Fi: 3e:22:fb:00:00:01"))
        XCTAssertFalse(MacNetworkSource.isPrivate("Wi-Fi: 3c:22:fb:00:00:01"))
    }

    /// The app list can't be hidden by any setting, so it promises no points.
    func testAppListIsNotInTheScore() {
        let def = MacSignalCatalogue.list.first { $0.id == "mac-installed-apps" }
        XCTAssertEqual(def?.fix.level, .onlyApple)
    }

    /// The Mac's name is set in General › About now, and Passwords opens its own app.
    func testNameAndPasswordsGoToTheRightPlace() {
        XCTAssertEqual(MacSignalCatalogue.list.first { $0.id == "mac-computer-name" }?.fix.settingsPane, MacSignalCatalogue.Pane.about)
        let name = CheckUpGuide.macSteps.first { $0.id == "mac-sharing" }
        XCTAssertEqual(name?.pane, MacSignalCatalogue.Pane.about)
        XCTAssertEqual(name?.secondPane?.pane, MacSignalCatalogue.Pane.sharing)
    }
}
