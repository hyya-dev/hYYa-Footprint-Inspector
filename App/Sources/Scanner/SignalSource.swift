// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// The permission a source needs before it can read anything. `nil` for passive sources.
enum PermissionKind: String, CaseIterable, Identifiable, Sendable {
    case motion, location, camera, bluetooth, localNetwork, contacts, photos, calendars, reminders, music

    var id: String { rawValue }

    var section: SignalSection {
        switch self {
        case .motion: .motion
        case .location: .location
        case .camera: .camera
        case .bluetooth: .bluetooth
        case .localNetwork: .localNetwork
        case .contacts: .contacts
        case .photos: .photos
        case .calendars: .calendars
        case .reminders: .reminders
        case .music: .music
        }
    }
}

/// Where a permission currently stands, as far as our own app is concerned.
enum PermissionState: Sendable, Equatable {
    case notAsked, granted, limited, denied, unavailable
}

/// Reads one group of signals from this phone.
///
/// Sources run on the main actor because most of the APIs involved (UIKit, AVAudioSession,
/// accessibility flags) expect it, and each read is quick. Slow work (sensor sampling, network
/// browsing) awaits inside `read()` without blocking.
@MainActor
protocol SignalSource {
    /// The sections this source fills, so the UI can show a placeholder while it runs.
    var sections: [SignalSection] { get }
    /// `nil` for passive and advanced sources.
    var permission: PermissionKind? { get }
    /// Current permission state without prompting. Passive sources return `.granted`.
    func permissionState() -> PermissionState
    /// Prompts for the permission (if needed) and returns the resulting state.
    func requestPermission() async -> PermissionState
    /// Reads every signal this source covers. Must never prompt.
    func read() async -> [SignalReading]
}

extension SignalSource {
    var permission: PermissionKind? { nil }
    func permissionState() -> PermissionState { .granted }
    func requestPermission() async -> PermissionState { .granted }
}

// MARK: - Formatting helpers shared by sources

enum Format {
    static func bytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    /// Exact byte counts are the point for storage signals: show both.
    static func exactBytes(_ value: Int64) -> String {
        "\(bytes(value)) (\(value.formatted(.number)) bytes)"
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year().hour().minute().second())
    }

    static func yesNo(_ flag: Bool) -> String { flag ? "Yes" : "No" }
    static func onOff(_ flag: Bool) -> String { flag ? "On" : "Off" }

    static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }

    static func decimal(_ value: Double, digits: Int = 3) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }
}
