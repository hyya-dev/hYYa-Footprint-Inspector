// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Network
import UIKit

/// Local Network: a short Bonjour browse for every service type we declare in Info.plist.
///
/// iOS offers no way to read this permission, so we remember what we last saw. Browsing only
/// ever prompts once per install, so after the first answer it's safe to browse again.
@MainActor
final class LocalNetworkPermissionSource: SignalSource {
    let sections: [SignalSection] = [.localNetwork]
    let permission: PermissionKind? = .localNetwork

    private static let storageKey = "permission.localNetwork"

    func permissionState() -> PermissionState {
        switch UserDefaults.standard.string(forKey: Self.storageKey) {
        case "granted": .granted
        case "denied": .denied
        default: .notAsked
        }
    }

    private func remember(_ state: PermissionState) {
        UserDefaults.standard.set(state == .denied ? "denied" : "granted", forKey: Self.storageKey)
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }

        // Browsing shows the prompt. While it's on screen the app is inactive; once it closes we
        // look at what the browsers report.
        let session = BonjourSession(types: ["_airplay._tcp", "_companion-link._tcp", "_raop._tcp"])
        session.start()
        defer { session.stop() }

        let clock = ContinuousClock()
        let started = clock.now
        var sawPrompt = false
        while clock.now - started < .seconds(90) {
            try? await Task.sleep(for: .milliseconds(250))
            if session.collector.hasResults { break }
            let active = UIApplication.shared.applicationState == .active
            if !active { sawPrompt = true; continue }
            if sawPrompt {
                try? await Task.sleep(for: .seconds(1))
                break
            }
            // No prompt within a few seconds: iOS already has an answer for us.
            if clock.now - started > .seconds(3) { break }
        }

        let state: PermissionState = session.collector.looksDenied ? .denied : .granted
        remember(state)
        return state
    }

    func read() async -> [SignalReading] {
        guard permissionState() != .notAsked else { return [] }

        let types = (Bundle.main.object(forInfoDictionaryKey: "NSBonjourServices") as? [String]) ?? []
        let session = BonjourSession(types: types)
        session.start()
        try? await Task.sleep(for: .milliseconds(2500))
        session.stop()

        let collector = session.collector
        if collector.looksDenied {
            remember(.denied)
            return []
        }
        remember(.granted)

        let found = collector.snapshot()
        guard !found.isEmpty else {
            return [SignalReading(id: "lan-devices", value: "Nothing found on this network right now")]
        }
        let items = found.keys
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { name in
                let kinds = Set(found[name, default: []].map(Self.label)).sorted()
                return "\(name) · \(kinds.joined(separator: ", "))"
            }
        var reading = SignalReading(
            id: "lan-devices",
            value: "\(PermissionText.count(found.count, "named device or service", "named devices and services")) found",
            items: items
        )
        if found.keys.contains(where: PermissionText.looksLikeOwnersName) {
            reading.severityOverride = .high
            reading.note = "Some names include a first name, which can tell an app who lives or works here."
        }
        return [reading]
    }

    private static func label(_ type: String) -> String {
        switch type {
        case "_airplay._tcp", "_raop._tcp": "AirPlay"
        case "_companion-link._tcp": "Apple device"
        case "_hap._tcp", "_homekit._tcp": "HomeKit"
        case "_matter._tcp": "Matter"
        case "_googlecast._tcp": "Google Cast"
        case "_spotify-connect._tcp": "Spotify Connect"
        case "_sonos._tcp": "Sonos"
        case "_roku._tcp": "Roku"
        case "_ipp._tcp", "_ipps._tcp", "_printer._tcp": "Printer"
        case "_scanner._tcp", "_uscan._tcp": "Scanner"
        case "_smb._tcp", "_afpovertcp._tcp": "File sharing"
        case "_ssh._tcp", "_sftp-ssh._tcp": "Remote access"
        case "_rfb._tcp": "Screen sharing"
        case "_hue._tcp": "Philips Hue"
        case "_device-info._tcp": "Device info"
        case "_http._tcp": "Web page"
        case "_amzn-wplay._tcp": "Fire TV"
        default: type
        }
    }
}

/// A set of Bonjour browsers running side by side.
private final class BonjourSession {
    let collector = BonjourCollector()
    private var browsers: [NWBrowser] = []
    private let types: [String]
    private let queue = DispatchQueue(label: "com.hyya.footprintinspector.bonjour")

    init(types: [String]) {
        self.types = types
    }

    func start() {
        let collector = collector
        for type in types {
            let parameters = NWParameters()
            parameters.includePeerToPeer = true
            let browser = NWBrowser(for: .bonjour(type: type, domain: nil), using: parameters)
            browser.stateUpdateHandler = { state in
                collector.record(state, for: type)
            }
            browser.browseResultsChangedHandler = { results, _ in
                for result in results {
                    if case let .service(name, _, _, _) = result.endpoint {
                        collector.add(name: name, type: type)
                    }
                }
            }
            browser.start(queue: queue)
            browsers.append(browser)
        }
    }

    func stop() {
        browsers.forEach { $0.cancel() }
        browsers = []
    }
}

/// Collects names from browser callbacks, which arrive on a background queue.
private final class BonjourCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var found: [String: Set<String>] = [:]
    /// The latest answer from each browser: true when it's blocked by the permission.
    private var blocked: [String: Bool] = [:]

    /// `kDNSServiceErr_PolicyDenied`: the person said no to Local Network access.
    private static let policyDenied: Int32 = -65570

    func add(name: String, type: String) {
        lock.lock(); defer { lock.unlock() }
        found[name, default: []].insert(type)
    }

    func record(_ state: NWBrowser.State, for type: String) {
        lock.lock(); defer { lock.unlock() }
        switch state {
        case .ready:
            blocked[type] = false
        case let .waiting(error), let .failed(error):
            if case let .dns(code) = error, code == Self.policyDenied {
                blocked[type] = true
            }
        default:
            break
        }
    }

    var hasResults: Bool {
        lock.lock(); defer { lock.unlock() }
        return !found.isEmpty
    }

    /// Denied when a browser's latest state is the policy error and nothing was found.
    var looksDenied: Bool {
        lock.lock(); defer { lock.unlock() }
        return found.isEmpty && blocked.values.contains(true)
    }

    func snapshot() -> [String: Set<String>] {
        lock.lock(); defer { lock.unlock() }
        return found
    }
}
