// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// How an app gets at a signal.
enum SignalGroup: String, CaseIterable, Sendable {
    /// Readable by any app, with no prompt.
    case passive
    /// A public API used in a way it wasn't designed for. Still no prompt.
    case advanced
    /// Only after the user grants a permission.
    case permission
}

/// How much a signal helps someone recognise or profile the user.
enum Severity: Int, Comparable, Sendable {
    case low = 0, medium, high

    static func < (a: Severity, b: Severity) -> Bool { a.rawValue < b.rawValue }

    var label: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "Worth a look"
        }
    }
}

/// How long a value stays the same, which is what makes it useful for tracking.
enum Persistence: Sendable {
    case untilRestart, untilReinstall, untilVendorAppsDeleted, untilErase, hardware, untilYouChangeIt, changesOften, followsAppleAccount, untilUpdate

    var label: String {
        switch self {
        case .untilRestart: "Until you restart"
        case .untilVendorAppsDeleted: "Until you delete every app from that company"
        case .untilReinstall: "Until you reinstall the app"
        case .untilErase: "Until you erase the phone"
        case .hardware: "Fixed for this model"
        case .untilYouChangeIt: "Until you change the setting"
        case .changesOften: "Changes often"
        case .followsAppleAccount: "Follows your Apple Account"
        case .untilUpdate: "Until you update iOS"
        }
    }
}

/// The four fix levels agreed for the product (see CLAUDE.md).
enum FixLevel: Int, Sendable {
    /// One tap, done inside our app.
    case inApp = 1
    /// One tap opens the right place in Settings.
    case openSettings = 2
    /// A short change the user makes by following steps.
    case guided = 3
    /// Nothing the user can do; only Apple can close it.
    case onlyApple = 4

    var label: String {
        switch self {
        case .inApp: "Fix it here"
        case .openSettings: "Fix in Settings"
        case .guided: "You can fix this"
        case .onlyApple: "Only Apple can fix this"
        }
    }
}

struct Fix: Sendable {
    var level: FixLevel
    /// One sentence on what to do (or why nothing can be done).
    var summary: String
    /// Ordered steps for guided fixes. Empty when there's nothing to do.
    var steps: [String] = []

    static func onlyApple(_ summary: String = "No setting changes this. Only an iOS update from Apple can.") -> Fix {
        Fix(level: .onlyApple, summary: summary)
    }
    static func guided(_ summary: String, _ steps: [String]) -> Fix {
        Fix(level: .guided, summary: summary, steps: steps)
    }
    /// For signals that reflect a choice the user needs (accessibility, protective settings).
    static func leaveIt(_ summary: String) -> Fix {
        Fix(level: .onlyApple, summary: summary)
    }
}

/// What we know about the signal on the newest iOS.
enum IOSStatus: Sendable {
    case unverified
    case stillOpen
    case changed(String)
}

/// The sections the scan is grouped into.
enum SignalSection: String, CaseIterable, Identifiable, Sendable {
    case identity, system, storage, display, audio, language, accessibility, clipboard, motionSensors
    case network, fontsVoices, accountAndApp, graphics, security, web, reinstall
    case motion, location, camera, bluetooth, localNetwork, contacts, photos, calendars, reminders, music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .identity: "Device identity"
        case .system: "System"
        case .storage: "Storage"
        case .display: "Screen"
        case .audio: "Audio and accessories"
        case .language: "Language, region and time"
        case .accessibility: "Accessibility and appearance"
        case .clipboard: "Clipboard"
        case .motionSensors: "Motion sensors"
        case .network: "Network"
        case .fontsVoices: "Fonts and voices"
        case .accountAndApp: "Account and App Store"
        case .graphics: "Graphics and cellular"
        case .security: "Security set-up"
        case .web: "Web fingerprint"
        case .reinstall: "Remembered after deleting"
        case .motion: "Motion & Fitness"
        case .location: "Location"
        case .camera: "Camera"
        case .bluetooth: "Bluetooth"
        case .localNetwork: "Local Network"
        case .contacts: "Contacts"
        case .photos: "Photos"
        case .calendars: "Calendars"
        case .reminders: "Reminders"
        case .music: "Media & Apple Music"
        }
    }

    var symbol: String {
        switch self {
        case .identity: "iphone"
        case .system: "cpu"
        case .storage: "internaldrive"
        case .display: "rectangle.on.rectangle"
        case .audio: "airpods"
        case .language: "globe"
        case .accessibility: "accessibility"
        case .clipboard: "doc.on.clipboard"
        case .motionSensors: "gyroscope"
        case .network: "network"
        case .fontsVoices: "textformat"
        case .accountAndApp: "person.crop.circle"
        case .graphics: "antenna.radiowaves.left.and.right"
        case .security: "lock.shield"
        case .web: "safari"
        case .reinstall: "arrow.counterclockwise.circle"
        case .motion: "figure.walk"
        case .location: "location"
        case .camera: "camera"
        case .bluetooth: "dot.radiowaves.left.and.right"
        case .localNetwork: "wifi.router"
        case .contacts: "person.2"
        case .photos: "photo.on.rectangle"
        case .calendars: "calendar"
        case .reminders: "checklist"
        case .music: "music.note"
        }
    }

    var group: SignalGroup {
        switch self {
        case .web, .reinstall: .advanced
        case .motion, .location, .camera, .bluetooth, .localNetwork, .contacts, .photos, .calendars, .reminders, .music: .permission
        default: .passive
        }
    }
}

/// Everything we say about a signal. Values are read separately (``SignalReading``).
struct SignalDefinition: Identifiable, Sendable {
    let id: String
    let section: SignalSection
    let title: String
    /// What it tells an app, in plain words.
    let reveals: String
    /// Why iOS lets apps read it at all.
    let why: String
    let persistence: Persistence
    let severity: Severity
    let fix: Fix
    var status: IOSStatus = .unverified
}

/// A value read from this phone.
struct SignalReading: Identifiable, Sendable, Equatable {
    let id: String
    var value: String
    /// Extra lines (a list of keyboards, fonts, devices…). Shown in the detail view.
    var items: [String] = []
    /// Set when this reading on *this* phone deserves more attention than the definition's
    /// default (for example a first name found in an accessory name).
    var raisedSeverity: Severity? = nil
    /// A one-line, calm explanation of why this reading was raised.
    var note: String? = nil
}
