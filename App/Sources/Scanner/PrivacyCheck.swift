// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Observation

/// The four checks as one journey, so the Score page can show one overall score and where to go
/// next. Only counts are kept, never which apps were found or what they shared, and they're saved
/// on this device so the score is still there after a restart (owner, 2026-10-28). Settings ›
/// Clear history removes them.
@MainActor
@Observable
final class PrivacyCheck {
    /// Sensitive apps: how many answered, out of how many were checked.
    private(set) var sensitiveFound: Int?
    /// Tracker: how many apps shared data with outside advertising or analytics companies.
    private(set) var trackerSharing: Int?

    /// Where the counts are kept. `nil` keeps them in memory only (store screenshots, tests).
    private let defaults: UserDefaults?
    static let sensitiveKey = "result.sensitiveFound"
    static let trackerKey = "result.trackerSharing"

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        sensitiveFound = defaults?.object(forKey: Self.sensitiveKey) as? Int
        trackerSharing = defaults?.object(forKey: Self.trackerKey) as? Int
    }

    func recordSensitive(found: Int) { sensitiveFound = found; defaults?.set(found, forKey: Self.sensitiveKey) }
    func recordTracker(sharing: Int) { trackerSharing = sharing; defaults?.set(sharing, forKey: Self.trackerKey) }

    func clearSaved() {
        sensitiveFound = nil
        trackerSharing = nil
        defaults?.removeObject(forKey: Self.sensitiveKey)
        defaults?.removeObject(forKey: Self.trackerKey)
    }
}

/// One number for all four checks, out of 100. Higher is better. It's the average of the checks
/// done so far, so it never pretends to know about a check that hasn't been run.
struct OverallScore: Equatable, Sendable {
    enum Part: String, CaseIterable, Sendable {
        case footprint, sensitive, tracker, checkup

        static var onThisPlatform: [Part] { allCases }
    }

    /// The score of each check that has been done.
    let parts: [Part: Int]

    /// `trackerReviewed`: the Mac has no App Privacy Report to read, so its Tracker check counts
    /// as 100 once every place that shows powerful access has been looked through, like Check-up.
    init(footprint: Int?, sensitiveFound: Int?, trackerSharing: Int?, trackerReviewed: Bool = false, checkUpDone: Int, checkUpTotal: Int) {
        var p: [Part: Int] = [:]
        p[.footprint] = footprint
        p[.sensitive] = sensitiveFound.map(Self.sensitivePart)
        #if os(macOS)
        if trackerReviewed { p[.tracker] = 100 }
        #else
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
    #if os(macOS)
    static let trackerLine = "counts as 100 once you've looked through every place that shows which apps can watch you. Until then it isn't in the score."
    #else
    static let trackerLine = "100 if no app shared your data with outside advertising or analytics companies, then 20 less for each app that did."
    #endif
    static let explanation = """
    Your privacy score is the average of the checks you've done, out of 100. Higher is better.

    • Footprint: how much any app can read about this device. Everyone starts at 100; each thing worth a look that you can fix costs 10 points, each smaller one 2, and every 40 points lost halve it, so it never hits zero.
    • Sensitive apps: 100 if none of the apps you checked can be spotted, then 25 less for each one that can.
    • Tracker: \(trackerLine)
    • Check-up: counts as 100 once you've been through every Settings area. Until then it isn't in the score, so ticking areas off never lowers it.

    Sensitive apps and Tracker never go below 20. Only these numbers are saved on this device, never which apps you have. Things only Apple can fix don't count, because nothing you do changes them. The score isn't a measure of how unique your device is: that would need data from other devices, and this app never sends or receives any.
    """
}
