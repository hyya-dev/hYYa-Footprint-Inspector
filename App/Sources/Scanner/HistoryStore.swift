// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CryptoKit
import Foundation
import Observation

/// A saved scan. It deliberately holds **no readings**: only the score, which signals were worth
/// a look, and a salted fingerprint of each value so the next scan can tell what changed without
/// the file ever containing the values themselves. Only the count of sensitive apps is kept, never which ones.
struct ScanSnapshot: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let date: Date
    let osVersion: String
    let score: Int
    let findingCount: Int
    let concerningIDs: [String]
    /// Signal id → salted SHA-256 of its value, shortened.
    let valueHashes: [String: String]
}

/// What changed between two scans.
struct ScanComparison: Sendable, Equatable {
    let previous: ScanSnapshot
    let current: ScanSnapshot
    /// Were worth a look, aren't any more.
    let resolved: [String]
    /// Newly worth a look.
    let newConcerns: [String]
    /// Value changed (in both scans).
    let changed: [String]

    init(previous: ScanSnapshot, current: ScanSnapshot) {
        self.previous = previous
        self.current = current
        let before = Set(previous.concerningIDs), after = Set(current.concerningIDs)
        resolved = before.subtracting(after).sorted()
        newConcerns = after.subtracting(before).sorted()
        changed = current.valueHashes.compactMap { id, hash in
            guard let old = previous.valueHashes[id], old != hash else { return nil }
            return id
        }.sorted()
    }

    var scoreDelta: Int { current.score - previous.score }
    var osChanged: Bool { previous.osVersion != current.osVersion }
}

/// Scan history, kept in one file on this iPhone only: excluded from iCloud and device backups,
/// never sent anywhere, and cleared with one tap in Settings.
@MainActor
@Observable
final class HistoryStore {
    private(set) var snapshots: [ScanSnapshot] = []
    static let limit = 60

    private let fileURL: URL
    /// The salt lives beside the history file, so clearing one clears the other and a store in
    /// another directory (tests) never touches the app's.
    private let saltURL: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = base.appending(path: "scan-history.json")
        saltURL = base.appending(path: "scan-history.salt")
        load()
    }

    var latest: ScanSnapshot? { snapshots.last }

    func makeSnapshot(findings: [Finding], score: FootprintScore, osVersion: String, date: Date = Date()) -> ScanSnapshot {
        let salt = self.salt()
        var hashes: [String: String] = [:]
        for finding in findings {
            let material = salt + finding.id + "\u{1F}" + finding.reading.value + finding.reading.items.joined(separator: "\u{1F}")
            hashes[finding.id] = SHA256.hash(data: Data(material.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        }
        return ScanSnapshot(id: UUID(), date: date, osVersion: osVersion, score: score.value,
                            findingCount: findings.count,
                            concerningIDs: findings.filter(\.isConcerning).map(\.id).sorted(),
                            valueHashes: hashes)
    }

    func append(_ snapshot: ScanSnapshot) {
        snapshots.append(snapshot)
        if snapshots.count > Self.limit { snapshots.removeFirst(snapshots.count - Self.limit) }
        save()
    }

    func clear() {
        snapshots = []
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: saltURL)
    }

    private func salt() -> String {
        if let data = try? Data(contentsOf: saltURL), let existing = String(data: data, encoding: .utf8) {
            return existing
        }
        let fresh = UUID().uuidString + UUID().uuidString
        try? FileManager.default.createDirectory(at: saltURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Data(fresh.utf8).write(to: saltURL, options: [.atomic, .completeFileProtection])
        Self.excludeFromBackup(saltURL)
        return fresh
    }

    /// Neither the history nor its salt goes into iCloud or computer backups.
    private static func excludeFromBackup(_ url: URL) {
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ScanSnapshot].self, from: data) else { return }
        snapshots = decoded
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshots)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            var url = fileURL
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
        } catch {
            // History is a convenience; a failed save must never break a scan.
        }
    }
}
