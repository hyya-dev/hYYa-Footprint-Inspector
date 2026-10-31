// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Observation
import SwiftUI

/// The four checks as one journey, so the Score page can show one overall score and where to go
/// next. Only counts and choices are kept, never which apps were found or what they shared. They
/// live in a file of their own, outside iCloud and computer backups, so the score is still there
/// after a restart (owner, 2026-10-28). Settings › Clear history removes them.
@MainActor
@Observable
final class PrivacyCheck {
    private struct Saved: Codable {
        var sensitiveFound: Int?
        var trackerSharing: Int?
        var checkedAt: Date?
        var checkUpDone = ""
        var sensitiveCategories = ""
        var trackerChecked = ""
    }

    private var saved = Saved()
    private var readable = true
    /// Where it's all kept. `nil` keeps it in memory only (store screenshots, tests).
    private let fileURL: URL?

    static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appending(path: "check-results.json")
    }

    /// Sensitive apps: how many answered, out of how many were checked.
    var sensitiveFound: Int? { saved.sensitiveFound }
    /// Tracker: how many apps shared data with outside advertising or analytics companies.
    var trackerSharing: Int? { saved.trackerSharing }
    /// When a Sensitive, Tracker or Check-up check last ran. Footprint scans have their own dates.
    var checkedAt: Date? { saved.checkedAt }
    /// The Check-up areas ticked, comma-separated.
    var checkUpDone: String {
        get { saved.checkUpDone }
        set { saved.checkUpDone = newValue; saved.checkedAt = Date(); save() }
    }
    /// The kinds of apps chosen, comma-separated.
    var sensitiveCategories: String {
        get { saved.sensitiveCategories }
        set { saved.sensitiveCategories = newValue; save() }
    }
    /// The Mac's Tracker places looked through, comma-separated.
    var trackerChecked: String {
        get { saved.trackerChecked }
        set { saved.trackerChecked = newValue; saved.checkedAt = Date(); save() }
    }

    init(fileURL: URL? = PrivacyCheck.defaultURL) {
        self.fileURL = fileURL
        guard let fileURL else { return }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Unreadable while the device is locked: keep what's there rather than save over it.
            guard let data = try? Data(contentsOf: fileURL) else { readable = false; return }
            saved = (try? JSONDecoder().decode(Saved.self, from: data)) ?? Saved()
        } else {
            moveFromDefaults()
        }
    }

    func recordSensitive(found: Int) { saved.sensitiveFound = found; saved.checkedAt = Date(); save() }
    func recordTracker(sharing: Int) { saved.trackerSharing = sharing; saved.checkedAt = Date(); save() }

    func clearSaved() {
        saved = Saved()
        if let fileURL { try? FileManager.default.removeItem(at: fileURL) }
    }

    /// Versions up to 1.0.2 kept these in UserDefaults, which goes into backups. Reads the app's
    /// own saved domain, not launch arguments, which UserDefaults would otherwise let override it.
    private func moveFromDefaults() {
        let keys = ["result.sensitiveFound", "result.trackerSharing", "checkUpDone", "sensitiveCategories", TrackerPlaces.storageKey]
        let defaults = UserDefaults.standard
        let old = Bundle.main.bundleIdentifier.flatMap(defaults.persistentDomain(forName:)) ?? [:]
        guard keys.contains(where: { old[$0] != nil }) else { return }
        saved.sensitiveFound = old[keys[0]] as? Int
        saved.trackerSharing = old[keys[1]] as? Int
        saved.checkUpDone = old[keys[2]] as? String ?? ""
        saved.sensitiveCategories = old[keys[3]] as? String ?? ""
        saved.trackerChecked = old[keys[4]] as? String ?? ""
        // The old values go only once they're safely in the file.
        if save() { keys.forEach(defaults.removeObject(forKey:)) }
    }

    @discardableResult private func save() -> Bool {
        guard readable, var url = fileURL, let data = try? JSONEncoder().encode(saved) else { return false }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard (try? data.write(to: url, options: [.atomic, .completeFileProtection])) != nil else { return false }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        return true
    }
}

/// Reads and writes one saved value on `PrivacyCheck`, the way `@AppStorage` would in a view.
@MainActor
@propertyWrapper
struct CheckStored: DynamicProperty {
    @Environment(PrivacyCheck.self) private var check
    private let key: ReferenceWritableKeyPath<PrivacyCheck, String>

    init(_ key: ReferenceWritableKeyPath<PrivacyCheck, String>) { self.key = key }

    var wrappedValue: String {
        get { check[keyPath: key] }
        nonmutating set { check[keyPath: key] = newValue }
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
