// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Observation

/// A reading paired with what we say about it.
struct Finding: Identifiable, Sendable {
    let definition: SignalDefinition
    let reading: SignalReading
    var id: String { definition.id }
    /// The reading's own assessment wins when it has one: a reader can raise a signal (a first
    /// name found) or lower it (a setting left at its ordinary default).
    var severity: Severity { reading.severityOverride ?? definition.severity }
    var isConcerning: Bool { severity == .high }
}

/// Runs the scan and holds the results. Results live in memory only: nothing is saved.
@MainActor
@Observable
final class Scanner {
    enum Phase: Equatable { case idle, scanning, done }

    private(set) var phase: Phase = .idle
    private(set) var readings: [String: SignalReading] = [:]
    private(set) var permissionStates: [PermissionKind: PermissionState] = [:]
    private(set) var loadingPermissions: Set<PermissionKind> = []
    private(set) var lastScan: Date?
    /// 0…1 while scanning, for the progress ring and haptic ticks.
    private(set) var progress: Double = 0
    /// What changed since the scan before this one. `nil` on the first scan.
    private(set) var comparison: ScanComparison?

    let history: HistoryStore

    init(history: HistoryStore) {
        self.history = history
    }

    #if os(iOS)
    let passiveSources: [any SignalSource] = [
        IdentitySource(), SystemSource(), StorageSource(), DisplaySource(), AudioSource(),
        LanguageSource(), AccessibilitySource(), ClipboardSource(), MotionSensorSource(),
        NetworkSource(), FontsVoicesSource(), AccountSource(), GraphicsSource(), SecuritySource(),
        WebFingerprintSource(), ReinstallSource(),
    ]
    #else
    let passiveSources: [any SignalSource] = MacSources.all
    #endif

    /// Forgets the last scan, for Clear history: nothing from it stays on screen or in memory.
    func reset() {
        guard phase != .scanning else { return }
        phase = .idle
        readings = [:]
        comparison = nil
        lastScan = nil
        progress = 0
    }

    /// Reads every passive and advanced signal, plus any permission category already granted.
    /// `quietly` re-reads in place, without the scanning screen: used when the app comes back to
    /// the screen and after the fix walk-through, so a fix shows in the score straight away. A
    /// quiet scan is saved to history only when something changed.
    func scan(quietly: Bool = false) async {
        guard phase != .scanning else { return }
        let before = history.latest
        if !quietly { phase = .scanning }
        progress = 0
        var fresh: [String: SignalReading] = [:]
        for (i, source) in passiveSources.enumerated() {
            for reading in await source.read() { fresh[reading.id] = reading }
            progress = Double(i + 1) / Double(passiveSources.count)
        }
        readings.merge(fresh) { $1 }
        refreshPermissionStates()
        for kind in PermissionKind.onThisPlatform where isReadable(permissionStates[kind]) {
            await readPermission(kind)
        }
        lastScan = Date()
        let snapshot = history.makeSnapshot(findings: allFindings, score: score,
                                            osVersion: ProcessInfo.processInfo.operatingSystemVersionString)
        let unchanged = before.map { $0.score == snapshot.score && $0.concerningIDs == snapshot.concerningIDs } ?? false
        if !(quietly && unchanged) {
            comparison = before.map { ScanComparison(previous: $0, current: snapshot) }
            history.append(snapshot)
        }
        phase = .done
    }

    var score: FootprintScore { FootprintScore(findings: allFindings) }

    func refreshPermissionStates() {
        for kind in PermissionKind.onThisPlatform {
            permissionStates[kind] = PermissionSources.source(for: kind).permissionState()
        }
    }

    /// "Show me": asks for the permission if needed, then reads that category.
    func reveal(_ kind: PermissionKind) async {
        let source = PermissionSources.source(for: kind)
        loadingPermissions.insert(kind)
        defer { loadingPermissions.remove(kind) }
        var state = source.permissionState()
        if state == .notAsked { state = await source.requestPermission() }
        permissionStates[kind] = state
        if isReadable(state) { await readPermission(kind) }
    }

    private func readPermission(_ kind: PermissionKind) async {
        let readings = await PermissionSources.source(for: kind).read()
        for reading in readings { self.readings[reading.id] = reading }
    }

    private func isReadable(_ state: PermissionState?) -> Bool {
        state == .granted || state == .limited
    }

    // MARK: Views of the results

    func findings(in section: SignalSection) -> [Finding] {
        SignalCatalogue.definitions(in: section).compactMap { def in
            readings[def.id].map { Finding(definition: def, reading: $0) }
        }
    }

    var allFindings: [Finding] {
        SignalSection.onThisPlatform.flatMap(findings(in:))
    }

    /// What any app can read with no prompt: everything except findings from granted permissions.
    var findingsWithoutAsking: [Finding] {
        allFindings.filter { $0.definition.section.group != .permission }
    }

    var concerning: [Finding] {
        allFindings.filter(\.isConcerning)
    }
}
