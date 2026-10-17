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

    let passiveSources: [any SignalSource] = [
        IdentitySource(), SystemSource(), StorageSource(), DisplaySource(), AudioSource(),
        LanguageSource(), AccessibilitySource(), ClipboardSource(), MotionSensorSource(),
        NetworkSource(), FontsVoicesSource(), AccountSource(), GraphicsSource(), SecuritySource(),
        WebFingerprintSource(), ReinstallSource(),
    ]

    /// Reads every passive and advanced signal, plus any permission category already granted.
    func scan() async {
        phase = .scanning
        progress = 0
        var fresh: [String: SignalReading] = [:]
        for (i, source) in passiveSources.enumerated() {
            for reading in await source.read() { fresh[reading.id] = reading }
            progress = Double(i + 1) / Double(passiveSources.count)
        }
        readings.merge(fresh) { $1 }
        refreshPermissionStates()
        for kind in PermissionKind.allCases where isReadable(permissionStates[kind]) {
            await readPermission(kind)
        }
        lastScan = Date()
        let snapshot = history.makeSnapshot(findings: allFindings, score: score,
                                            osVersion: ProcessInfo.processInfo.operatingSystemVersionString)
        comparison = history.latest.map { ScanComparison(previous: $0, current: snapshot) }
        history.append(snapshot)
        phase = .done
    }

    var score: FootprintScore { FootprintScore(findings: allFindings) }

    func refreshPermissionStates() {
        for kind in PermissionKind.allCases {
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
        SignalSection.allCases.flatMap(findings(in:))
    }

    var concerning: [Finding] {
        allFindings.filter(\.isConcerning)
    }
}
