// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Foundation
@testable import FootprintInspector

@MainActor
struct ScoreHistoryTests {
    private func finding(_ id: String, value: String = "x", raise: Severity? = nil) -> Finding {
        let def = SignalCatalogue.definition(id)!
        return Finding(definition: def, reading: SignalReading(id: id, value: value, severityOverride: raise))
    }

    private func tempStore() -> HistoryStore {
        HistoryStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    }

    @Test func emptyScanScoresFullMarks() {
        #expect(FootprintScore(findings: []).value == 100)
    }

    @Test func onlyAppleIsListedNotScored() {
        // boot-time: high + guided (fixable) = 10; volume-created: high + only Apple = not scored.
        let score = FootprintScore(findings: [finding("boot-time"), finding("volume-created")])
        #expect(score.value == 84)
        #expect(score.reachable == 16)
        #expect(score.fixableCount == 1)
        #expect(score.onlyAppleCount == 1)
    }

    @Test func defaultsDoNotCost() {
        let score = FootprintScore(findings: [finding("keyboards", raise: .low), finding("tracking", raise: .low)])
        #expect(score.value == 100)
    }

    @Test func scoreFallsSteeplyButNeverHitsZero() {
        #expect(FootprintScore.value(lost: 40) == 50)
        #expect(FootprintScore(findings: Array(repeating: finding("boot-time"), count: 11)).value == 15)
        #expect(FootprintScore(findings: Array(repeating: finding("boot-time"), count: 30)).value > 0)
    }

    /// The history file must never contain a reading's value.
    @Test func snapshotsHoldNoValues() throws {
        let store = tempStore()
        let secret = "Sam's AirPods Pro"
        let f = [finding("audio-route", value: secret, raise: .high)]
        let snap = store.makeSnapshot(findings: f, score: FootprintScore(findings: f), osVersion: "iOS 26.4")
        let json = String(decoding: try JSONEncoder().encode(snap), as: UTF8.self)
        #expect(!json.contains("Sam"))
        #expect(snap.concerningIDs == ["audio-route"])
    }

    @Test func comparisonSpotsResolvedAndChanged() {
        let store = tempStore()
        let before = [finding("audio-route", value: "Sam's AirPods", raise: .high), finding("battery", value: "50%")]
        let after = [finding("audio-route", value: "Headphones"), finding("battery", value: "49%")]
        let a = store.makeSnapshot(findings: before, score: FootprintScore(findings: before), osVersion: "iOS 26.4")
        let b = store.makeSnapshot(findings: after, score: FootprintScore(findings: after), osVersion: "iOS 26.4")
        let c = ScanComparison(previous: a, current: b)
        #expect(c.resolved == ["audio-route"])
        #expect(c.newConcerns.isEmpty)
        #expect(Set(c.changed) == ["audio-route", "battery"])
        #expect(c.scoreDelta > 0)
    }

    @Test func historyPersistsAndClears() {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let store = HistoryStore(directory: dir)
        store.append(store.makeSnapshot(findings: [], score: FootprintScore(findings: []), osVersion: "iOS 26.4"))
        #expect(HistoryStore(directory: dir).snapshots.count == 1)
        store.clear()
        #expect(HistoryStore(directory: dir).snapshots.isEmpty)
    }
}
