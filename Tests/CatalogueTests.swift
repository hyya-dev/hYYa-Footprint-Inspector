// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Foundation
@testable import FootprintInspector

struct CatalogueTests {
    @Test func signalIDsAreUnique() {
        let ids = (SignalCatalogue.passive + SignalCatalogue.advanced + SignalCatalogue.permission).map(\.id)
        #expect(Set(ids).count == ids.count, "Duplicate signal ids: \(ids.filter { id in ids.filter { $0 == id }.count > 1 })")
    }

    @Test func everySectionHasADefinition() {
        for section in SignalSection.allCases {
            #expect(!SignalCatalogue.definitions(in: section).isEmpty, "No definitions for \(section)")
        }
    }

    @Test func guidedFixesHaveSteps() {
        for def in SignalCatalogue.all.values where def.fix.level == .guided {
            #expect(!def.fix.steps.isEmpty, "\(def.id) is guided but has no steps")
        }
    }

    /// iOS only answers canOpenURL for declared schemes, and the iOS 27 SDK caps the list at 25.
    @Test func sensitiveSchemesMatchInfoPlist() throws {
        let declared = try #require(Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String])
        #expect(declared.count <= 25)
        #expect(Set(declared) == Set(SensitiveCatalogue.allSchemes))
        #expect(SensitiveCatalogue.allSchemes.count == Set(SensitiveCatalogue.allSchemes).count)
    }

    @Test func noCustomURLSchemeOfOurOwn() {
        // docs/HYYA-APPS-DETECTABILITY.md: other apps must not be able to detect this one.
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") == nil)
    }

    @Test(arguments: [
        ("Sam's AirPods Pro", "Sam"),
        ("Léa’s iPhone", "Léa"),
        ("Living Room", nil),
        ("AirPods", nil),
    ])
    func ownerNameDetection(name: String, expected: String?) {
        #expect(OwnerName.find(in: name) == expected)
    }
}

@MainActor
struct PassiveSourceTests {
    /// Every reading a passive source produces must have something to say about it.
    @Test func passiveReadingsAllHaveDefinitions() async {
        let scanner = Scanner(history: HistoryStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        for source in scanner.passiveSources {
            for reading in await source.read() {
                #expect(SignalCatalogue.definition(reading.id) != nil, "No definition for reading \(reading.id)")
            }
        }
    }
}
