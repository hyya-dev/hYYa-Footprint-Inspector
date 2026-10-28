// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import SwiftUI
import Foundation
@testable import FootprintInspector

struct PrivacyCheckTests {
    @Test func averagesOnlyTheChecksDone() {
        let none = OverallScore(footprint: nil, sensitiveFound: nil, trackerSharing: nil, checkUpDone: 0, checkUpTotal: 17)
        #expect(none.value == nil && none.doneCount == 0)

        let one = OverallScore(footprint: 62, sensitiveFound: nil, trackerSharing: nil, checkUpDone: 0, checkUpTotal: 17)
        #expect(one.value == 62 && one.doneCount == 1)

        let three = OverallScore(footprint: 62, sensitiveFound: 1, trackerSharing: 0, checkUpDone: 0, checkUpTotal: 17)
        #expect(three.value == Int((Double(62 + 75 + 100) / 3).rounded()))
    }

    /// Ticking Check-up areas must never lower the score: it only counts, as 100, once finished.
    @Test func checkUpNeverLowersTheScore() {
        let before = OverallScore(footprint: 62, sensitiveFound: nil, trackerSharing: nil, checkUpDone: 0, checkUpTotal: 17)
        for done in 1..<17 {
            let partway = OverallScore(footprint: 62, sensitiveFound: nil, trackerSharing: nil, checkUpDone: done, checkUpTotal: 17)
            #expect(partway.value == before.value)
        }
        let finished = OverallScore(footprint: 62, sensitiveFound: nil, trackerSharing: nil, checkUpDone: 17, checkUpTotal: 17)
        #expect(finished.value! > before.value!)
    }

    @Test func partsHaveAFloor() {
        #expect(OverallScore.sensitivePart(0) == 100)
        #expect(OverallScore.sensitivePart(10) == 20)
        #expect(OverallScore.trackerPart(0) == 100)
        #expect(OverallScore.trackerPart(10) == 20)
    }

    /// Every iPhone finding has a plain headline and one short line, in device-neutral words.
    @Test func everyFindingHasPlainWords() {
        let defs = SignalCatalogue.passive + SignalCatalogue.advanced + SignalCatalogue.permission
        let device = /(?i)\b(iphone|ipad|phone)\b/
        for d in defs {
            let entry = PlainWords.text[d.id]
            #expect(entry != nil, "No plain words for \(d.id)")
            if let entry {
                #expect(entry.headline.count <= 60, "Headline too long: \(d.id)")
                #expect(entry.headline.firstMatch(of: device) == nil && entry.brief.firstMatch(of: device) == nil, "Device word in \(d.id)")
            }
        }
    }

    /// The spyware and leaked-password steps are guidance, not detection claims.
    @Test func securityStepsMakeNoDetectionClaims() {
        let ids = ["updates", "restart", "passwords", "lockdown"]
        let steps = CheckUpGuide.iosSteps.filter { ids.contains($0.id) }
        #expect(steps.count == ids.count)
        let claims = /(?i)\b(scan\w* for|detect\w*|remov\w* spyware|antivirus|virus)\b/
        for s in steps { #expect(s.why.firstMatch(of: claims) == nil, "Claim in \(s.id)") }
    }
}

/// Owner's Mac test, 2026-10-28: the score must survive a restart and follow what was fixed.
@MainActor
struct LiveScoreTests {
    @Test func checkResultsAreKeptAndCleared() throws {
        let suite = "test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        PrivacyCheck(defaults: defaults).recordSensitive(found: 2)
        let reopened = PrivacyCheck(defaults: defaults)
        #expect(reopened.sensitiveFound == 2)
        reopened.clearSaved()
        #expect(PrivacyCheck(defaults: defaults).sensitiveFound == nil)
        // In-memory (store screenshots) never writes anything.
        PrivacyCheck(defaults: nil).recordTracker(sharing: 3)
        #expect(PrivacyCheck(defaults: defaults).trackerSharing == nil)
    }

    @Test func aRestartWithinAWeekCountsAsDone() {
        let now = Date()
        #expect(RecentRestart.isRecent(boot: now.addingTimeInterval(-2 * 24 * 3600), now: now))
        #expect(!RecentRestart.isRecent(boot: now.addingTimeInterval(-8 * 24 * 3600), now: now))
    }

    /// The restart step is ticked by itself when the device restarted recently, and has no
    /// Settings button: restarting and the Passwords app aren't in Settings.
    @Test func restartAndPasswordsAreNotSettings() {
        #expect(CheckUpGuide.iosSteps.contains { $0.id == "restart" })
        #expect(CheckUpGuide.macSteps.first { $0.id == "mac-passwords" }?.app?.bundleID == "com.apple.Passwords")
        #expect(SignalCatalogue.passive.first { $0.id == "boot-time" }?.isRestart == true)
    }

    /// Every fix that promises points must be one a scan can see: the score only moves for those.
    @Test func everyPointPromisedCanBeSeenByAScan() {
        for d in SignalCatalogue.list where d.severity == .high && d.fix.level != .onlyApple {
            #expect(!d.fix.summary.isEmpty, "\(d.id) has no fix")
        }
    }
}

/// Security review 2026-10-24: a crafted report file can't crash the app or exhaust memory.
struct ReportHardeningTests {
    @Test func hugeHitCountsAreClampedNotOverflowed() throws {
        let line = #"{"type":"networkActivity","bundleID":"com.example.x","domain":"a.example.com","hits":9223372036854775807}"#
        let data = Data(Array(repeating: line, count: 50).joined(separator: "\n").utf8)
        let report = try PrivacyReport.read(data)
        let hits = report.ranked.first?.sites.values.first?.hits ?? 0
        #expect(hits > 0 && hits <= 50 * 1_000_000)
    }

    @Test func oversizedFilesAreRefused() {
        let big = Data(count: PrivacyReport.maxBytes + 1)
        #expect(throws: PrivacyReport.ReadError.self) { try PrivacyReport.read(big) }
    }
}
