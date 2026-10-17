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
    var severity: Severity { max(definition.severity, reading.raisedSeverity ?? .low) }
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

    let passiveSources: [any SignalSource] = [
        IdentitySource(), SystemSource(), StorageSource(), DisplaySource(), AudioSource(),
        LanguageSource(), AccessibilitySource(), ClipboardSource(), MotionSensorSource(),
        NetworkSource(), FontsVoicesSource(), AccountSource(), GraphicsSource(), SecuritySource(),
        WebFingerprintSource(), ReinstallSource(),
    ]

    /// Reads every passive and advanced signal, plus any permission category already granted.
    func scan() async {
        phase = .scanning
        var fresh: [String: SignalReading] = [:]
        for source in passiveSources {
            for reading in await source.read() { fresh[reading.id] = reading }
        }
        readings.merge(fresh) { $1 }
        refreshPermissionStates()
        for kind in PermissionKind.allCases where isReadable(permissionStates[kind]) {
            await readPermission(kind)
        }
        lastScan = Date()
        phase = .done
    }

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
