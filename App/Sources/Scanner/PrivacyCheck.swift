// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Observation

/// The four checks as one journey, so the first page can show one overall score and where to go
/// next. The sensitive-app and Tracker results are held in memory only and cleared when the app
/// leaves the screen, like the results themselves: nothing here is ever saved.
@MainActor
@Observable
final class PrivacyCheck {
    /// Sensitive apps: how many answered, out of how many were checked.
    private(set) var sensitiveFound: Int?
    /// Tracker: how many apps shared data with outside advertising or analytics companies.
    private(set) var trackerSharing: Int?

    func recordSensitive(found: Int) { sensitiveFound = found }
    func recordTracker(sharing: Int) { trackerSharing = sharing }

    func clearSessionResults() {
        sensitiveFound = nil
        trackerSharing = nil
    }
}

/// One number for all four checks, out of 100. Higher is better. It's the average of the checks
/// done so far, so it never pretends to know about a check that hasn't been run.
struct OverallScore: Equatable, Sendable {
    enum Part: String, CaseIterable, Sendable {
        case footprint, sensitive, tracker, checkup

        /// The Mac has no App Privacy Report to read, so its Tracker page is guidance, not a check.
        static var onThisPlatform: [Part] {
            #if os(macOS)
            [.footprint, .sensitive, .checkup]
            #else
            allCases
            #endif
        }
    }

    /// The score of each check that has been done.
    let parts: [Part: Int]

    init(footprint: Int?, sensitiveFound: Int?, trackerSharing: Int?, checkUpDone: Int, checkUpTotal: Int) {
        var p: [Part: Int] = [:]
        p[.footprint] = footprint
        p[.sensitive] = sensitiveFound.map(Self.sensitivePart)
        #if os(iOS)
        p[.tracker] = trackerSharing.map(Self.trackerPart)
        #endif
        // Check-up counts once every area is done, so ticking an area never lowers the score.
        if checkUpTotal > 0 && checkUpDone >= checkUpTotal { p[.checkup] = 100 }
        parts = p
    }

    var doneCount: Int { parts.count }
    var total: Int { Part.onThisPlatform.count }

    /// The average of the checks done, or nil before the first one.
    var value: Int? {
        guard !parts.isEmpty else { return nil }
        return Int((Double(parts.values.reduce(0, +)) / Double(parts.count)).rounded())
    }

    enum Level: Sendable {
        case good, fair, weak
        var title: String {
            switch self {
            case .good: "Well protected"
            case .fair: "Partly protected"
            case .weak: "Easy to track"
            }
        }
    }

    var level: Level? {
        guard let value else { return nil }
        return switch value {
        case 75...: .good
        case 50..<75: .fair
        default: .weak
        }
    }

    /// Every app that answers costs 25 points, down to 20.
    static func sensitivePart(_ found: Int) -> Int { max(20, 100 - 25 * found) }
    /// Every app that shares with outside ad or analytics companies costs 20 points, down to 20.
    static func trackerPart(_ sharing: Int) -> Int { max(20, 100 - 20 * sharing) }
    static let explanation = """
    Your privacy score is the average of the checks you've done, out of 100. Higher is better.

    • Footprint: how much any app can read about this device. Everyone starts at 100; each thing worth a look that you can fix costs 10 points, each smaller one 2, and every 40 points lost halve it, so it never hits zero.
    • Sensitive apps: 100 if none of the apps you checked can be spotted, then 25 less for each one that can.
    • Tracker: 100 if no app shared your data with outside advertising or analytics companies, then 20 less for each app that did.
    • Check-up: counts as 100 once you've been through every Settings area. Until then it isn't in the score, so ticking areas off never lowers it.

    Sensitive apps and Tracker never go below 20. Things only Apple can fix don't count, because nothing you do changes them. The score isn't a measure of how unique your device is: that would need data from other devices, and this app never sends or receives any.
    """
}
