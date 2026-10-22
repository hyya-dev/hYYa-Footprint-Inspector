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
        for section in SignalSection.onThisPlatform {
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

    /// The "who else can check" card names no organisation and makes no detection claim, and the
    /// Check-up covers device management (docs/WATCHERS-RESEARCH.md).
    @Test func othersCanCheckCopyAndDeviceManagementStep() {
        let lines = [SensitiveView.othersLine, SensitiveView.websiteLine]
        let claims = /(?i)\b(spy\w*|malware|virus|threat|detect\w*)\b/
        for line in lines { #expect(line.firstMatch(of: claims) == nil, "Claim in: \(line)") }
        #expect(CheckUpGuide.iosSteps.contains { $0.id == "device-management" })
        #expect(CheckUpGuide.macSteps.contains { $0.id == "mac-device-management" && $0.pane != nil })
    }

    /// The first reminder comes days after turning it on, never the same day.
    @Test func scanReminderFirstFiresLater() throws {
        let cal = Calendar(identifier: .gregorian)
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 9)))
        #expect(ScanReminder.off.trigger(from: now, calendar: cal) == nil)
        let weekly = try #require(ScanReminder.weekly.trigger(from: now, calendar: cal)?.dateComponents)
        let nextWeekly = try #require(cal.nextDate(after: now, matching: weekly, matchingPolicy: .nextTime))
        #expect(nextWeekly.timeIntervalSince(now) > 5 * 86_400)
        let monthly = try #require(ScanReminder.monthly.trigger(from: now, calendar: cal)?.dateComponents)
        let nextMonthly = try #require(cal.nextDate(after: now, matching: monthly, matchingPolicy: .nextTime))
        #expect(nextMonthly.timeIntervalSince(now) > 25 * 86_400)
        #expect(!ScanReminder.notificationBody.isEmpty)
    }

    /// The scoreboard reads the system's name and version; a self-referencing getter once
    /// recursed until the stack ran out (found 2026-10-22, never shipped).
    @MainActor @Test func systemNameAndVersionResolve() {
        #expect(!System.name.isEmpty)
        #expect(System.version.split(separator: ".").count >= 2)
    }

    /// Reads both App Privacy Report layouts and judges plainly: only sharing with outside
    /// advertising or analytics companies is flagged; own servers, Apple, hosting and a company's
    /// own analytics are not; trackers inside opened content are the sender's, not the app's.
    @Test func privacyReportJudgesPlainly() throws {
        let r = PrivacyReport.sample
        let photo = try #require(r.apps.first { $0.bundleID == "com.example.photoeditor" })
        #expect(photo.uses[.photos] == 1)                       // begin/end pair counted once
        #expect(photo.verdict == .sharesOutside)
        #expect(photo.outsideCompanies.contains("Meta"))
        #expect(r.ranked.first?.bundleID == "com.example.photoeditor")

        let older = """
        {"stream":"com.apple.privacy.accounting.stream.tcc","accessor":{"identifier":"com.example.old","identifierType":"bundleID"},"tccService":"kTCCServiceAddressBook","identifier":"X","kind":"event","timestamp":"2021-09-01T10:00:00.000Z","version":3}
        """
        #expect(try PrivacyReport.read(Data(older.utf8)).apps.first?.uses[.contacts] == 1)
        #expect(throws: PrivacyReport.ReadError.self) { try PrivacyReport.read(Data("hello\nworld".utf8)) }

        #expect(SiteKind.of("api.hst.hyya.com", app: "com.hyya.encryptednotes") == .ownServers)
        #expect(SiteKind.of("oauth2.googleapis.com", app: "com.hyya.encryptednotes") == .cloud)
        #expect(SiteKind.of("amp-api.apps.apple.com", app: "com.hyya.encryptednotes") == .apple)
        #expect(SiteKind.of("x.supabase.co", app: "com.hyya.subscriptionstracker") == .cloud)
        #expect(SiteKind.of("app-analytics-services.com", app: "com.google.Maps") == .ownServers)
        #expect(SiteKind.of("app-analytics-services.com", app: "com.example.game") == .analytics)
        #expect(SiteKind.of("firebase-settings.crashlytics.com", app: "com.example.game") == .crashReports)
        #expect(SiteKind.of("d3abc.cloudfront.net", app: "com.czzhao.binance") == .cloud)
        #expect(SiteKind.of("api.open-meteo.com", app: "com.hyya.prayerpal") == .publicData)
        #expect(SiteKind.company(for: "nominatim.openstreetmap.org") == "Place names (OpenStreetMap)")

        let mail = PrivacyReport.AppActivity(bundleID: "com.apple.mobilemail", sites: [
            "x.r.us-east-1.awstrack.me": .init(domain: "x.r.us-east-1.awstrack.me", owner: nil, hits: 1, byApp: false)])
        #expect(mail.verdict == .contentTrackers)
        #expect(AppNames.name(for: "com.example.notes") == "Notes")
    }

    @Test func seriousFindingsSayWhatTheyMeanInPractice() {
        let serious = (SignalCatalogue.passive + SignalCatalogue.advanced + SignalCatalogue.permission + MacSignalCatalogue.list)
            .filter { $0.severity == .high }
        let missing = serious.filter { SignalImpact.inPractice[$0.id] == nil }.map(\.id)
        #expect(missing.isEmpty, "No 'in practice' line for: \(missing)")
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
