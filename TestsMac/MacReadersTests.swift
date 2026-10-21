// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest
@testable import FootprintInspector

/// Runs every Mac reader on this Mac and checks the catalogue covers what they return.
@MainActor
final class MacReadersTests: XCTestCase {
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
