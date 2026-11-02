// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import LocalAuthentication
#if os(iOS)
import UIKit
#endif

/// What this device has, read from the device itself, so a direction names what's really on it.
/// Apple's guides for iOS 26 and 27 use the same paths, so what differs is the hardware.
enum ThisDevice {
    /// "Face ID" or "Touch ID"; nil when the device has neither.
    static let biometry: String? = {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return switch context.biometryType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        default: nil
        }
    }()

    /// The Settings row that holds the passcode. It's named after how the device unlocks.
    static var passcodeRow: String { biometry.map { "\($0) & Passcode" } ?? "Passcode" }

    static var isTablet: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
}

/// iOS never tells one app which other apps hold a permission. Only Settings knows, so the
/// check-up walks the user through Settings, one area at a time.
struct CheckUpStep: Identifiable, Sendable {
    let id: String
    let title: String
    let symbol: String
    /// Why this area matters, in one or two sentences.
    let why: String
    /// Where to go, written as a Settings path.
    let path: String
    /// What to look for and the safest choice.
    let actions: [String]
    /// Mac only: the System Settings page "Open in System Settings" goes to.
    var pane: String? = nil
    /// Mac only: a second page this area needs, with its button title.
    var secondPane: (title: String, pane: String)? = nil
    /// An app to open instead of Settings, when the area isn't in Settings at all (Passwords).
    var app: (title: String, bundleID: String)? = nil
    /// False for steps added after 1.0.3: finishing Check-up must never lower a score, so people
    /// who finished keep their credit.
    var counts = true
    /// A short benefit for the list, in place of the path. Set for the newer, longer paths.
    var hint: String? = nil
}

enum CheckUpGuide {
    static var steps: [CheckUpStep] {
        #if os(macOS)
        macSteps
        #else
        // Stolen Device Protection is iPhone only.
        iosSteps.filter { !(ThisDevice.isTablet && $0.id == "stolen-device") }
        #endif
    }

    static let iosSteps: [CheckUpStep] = [
        .init(id: "safety-check", title: "Start with Safety Check", symbol: "checkmark.shield",
              why: "Apple's own review of who and what can reach your information. It covers people you share with and app permissions in one place.",
              path: "Settings › Privacy & Security › Safety Check",
              actions: ["Tap Manage Sharing & Access.", "Go through each screen and remove anything you don't recognise or no longer need."]),
        .init(id: "lock-device", title: "Lock your device", symbol: "lock",
              why: "Your passcode protects everything else on this device. A short Auto-Lock locks it soon after you put it down.",
              path: "Settings › \(ThisDevice.passcodeRow)",
              actions: ["Use a passcode of at least six digits. Passcode Options offers longer ones.",
                        "Set Auto-Lock to 30 seconds or 1 minute: Settings › Display & Brightness › Auto-Lock.",
                        "Under Allow Access When Locked, turn off what you don't need on the Lock Screen, such as Control Center."],
              counts: false, hint: "Passcode, Auto-Lock and Lock Screen"),
        .init(id: "apple-account", title: "Protect your Apple Account", symbol: "person.badge.key",
              why: "Your Apple Account can hold your photos, messages and backups. Two-factor authentication protects it even if your password leaks.",
              path: "Settings › [your name] › Sign-In & Security › Two-Factor Authentication",
              actions: ["Turn on Two-Factor Authentication.", "Add a trusted phone number you can always reach."],
              counts: false, hint: "Two-factor and a trusted number"),
        .init(id: "find-device", title: "Be able to find your device", symbol: "location.magnifyingglass",
              why: "If you lose your device, you can see where it is, lock it or erase it from another device.",
              path: "Settings › [your name] › Find My › Find My [your device]",
              actions: ["Turn on Find My.", "Turn on Find My network, so it can be found even when it's offline.", "Turn on Send Last Location."],
              counts: false, hint: "Find it even when it's offline"),
        .init(id: "stolen-device", title: "Stolen Device Protection", symbol: "lock.iphone",
              why: "If someone takes your device and knows your passcode, this adds extra checks before they can change sensitive settings away from familiar places.",
              path: "Settings › \(ThisDevice.passcodeRow) › Stolen Device Protection",
              actions: ["Turn it on. It may already be on.", "You'll need two-factor authentication, \(ThisDevice.biometry ?? "Face ID or Touch ID") and Significant Locations on."],
              counts: false, hint: "Extra checks if someone takes it"),
        .init(id: "lock-apps", title: "Lock sensitive apps", symbol: "app.badge.checkmark",
              why: "Locking an app asks for \(ThisDevice.biometry.map { "\($0) or " } ?? "")your passcode before it opens, even when your device is unlocked.",
              path: "Home Screen: touch and hold an app",
              actions: ["Choose Require \(ThisDevice.biometry ?? "Passcode").", "Some built-in apps can't be locked."],
              counts: false, hint: "\(ThisDevice.biometry ?? "A passcode") on the apps that matter"),
        .init(id: "social-apps", title: "Social media apps", symbol: "person.2.wave.2",
              why: "Social apps can learn a lot from what they're allowed to reach, and from what other apps and websites share with them.",
              path: "Settings › Apps, then a social app",
              actions: ["Turn off what the app doesn't need, such as location, contacts, microphone and camera.",
                        "In each app, open its privacy and ad settings and turn off what you don't want.",
                        "On Facebook and Instagram, look in Accounts Center or Meta Account settings for Your activity off Meta technologies and Ad preferences. Names can change, and some options aren't offered everywhere."],
              counts: false, hint: "What they can reach and share"),
        .init(id: "device-management", title: "VPN & Device Management", symbol: "gearshape.2",
              why: "A profile here can let someone manage this device, send your internet traffic through their servers, or read connections that are meant to be private.",
              path: "Settings › General › VPN & Device Management",
              actions: ["Tap each profile or management entry you don't recognise, then choose Remove.",
                        "Keep ones your work or school set up with you, and VPNs you installed yourself."]),
        .init(id: "updates", title: "Keep the system updated", symbol: "arrow.down.circle",
              why: "Updates close the holes that spyware uses to get in. It's the single best protection there is.",
              path: "Settings › General › Software Update › Automatic Updates",
              actions: ["Turn on Automatically Install.", "If an update is waiting, install it now."]),
        .init(id: "restart", title: "Restart once a week", symbol: "arrow.clockwise",
              why: "Some spyware lives only in memory and is cleared by a restart. It also gives apps a new restart time, so they can't use it to recognise you.",
              path: "Hold the side or top button and either volume button",
              actions: ["Drag the slider to turn the device off.", "Wait a few seconds, then hold the side or top button until the Apple logo appears.", "Do it again next week."]),
        .init(id: "passwords", title: "Check for leaked passwords", symbol: "key",
              why: "Apple's Passwords app warns you when a saved password has turned up in a known data leak. It checks without revealing your passwords, and this app sees nothing.",
              path: "Passwords app › Security",
              actions: ["Open the Passwords app and tap Security.", "Change any password marked as leaked or reused.", "In Settings › Apps › Passwords, keep Detect Compromised Passwords on."]),
        .init(id: "lockdown", title: "Protection from targeted spyware", symbol: "lock.shield",
              why: "Lockdown Mode is Apple's strongest defence against rare, targeted spyware such as Pegasus. Most people never need it; journalists, activists and officials should consider it.",
              path: "Settings › Privacy & Security › Lockdown Mode",
              actions: ["If your work could make you a target, turn on Lockdown Mode. Some features, such as link previews, will be limited.",
                        "If Apple ever warns you of a targeted attack, by email, message or at account.apple.com, follow its advice.",
                        "Otherwise, leave it off and keep your system updated."]),
        .init(id: "health", title: "Health", symbol: "heart.text.square",
              why: "Health data is the most personal information on your device: sleep, heart, cycles, medicines.",
              path: "Health app › your picture or initials › Privacy › Apps",
              actions: ["Open each app in the list.", "Turn off any data type the app doesn't truly need.", "Check Devices in the same place, and remove any you no longer use."]),
        .init(id: "location", title: "Location", symbol: "location",
              why: "Your location shows where you live, work and spend time.",
              path: "Settings › Privacy & Security › Location Services",
              actions: ["For each app, choose Never or While Using the App. Avoid Always.",
                        "Turn off Precise Location for apps that only need your city.",
                        "Look at System Services at the bottom and turn off what you don't use."]),
        .init(id: "photos", title: "Photos", symbol: "photo.on.rectangle",
              why: "Full Photos access lets an app see every picture and where each one was taken.",
              path: "Settings › Privacy & Security › Photos",
              actions: ["Choose Limited Access, and pick only the photos an app needs.", "Use None for apps that never need photos."]),
        .init(id: "contacts", title: "Contacts", symbol: "person.2",
              why: "Your contacts include other people's numbers and addresses, not just yours.",
              path: "Settings › Privacy & Security › Contacts",
              actions: ["Choose Limited Access, or turn access off for apps that don't need it."]),
        .init(id: "calendars", title: "Calendars and Reminders", symbol: "calendar",
              why: "Calendars show your routine, and their account names often give away where you work.",
              path: "Settings › Privacy & Security › Calendars, then Reminders",
              actions: ["Prefer Add Events Only for apps that just create events.", "Turn off access for apps you don't recognise."]),
        .init(id: "bluetooth-network", title: "Bluetooth and Local Network", symbol: "wifi.router",
              why: "These let apps see devices around you and on your Wi-Fi, often named after their owners.",
              path: "Settings › Privacy & Security › Bluetooth, then Local Network",
              actions: ["Turn off any app that doesn't connect to a device of yours."]),
        .init(id: "mic-camera", title: "Microphone and Camera", symbol: "mic",
              why: "Only apps you use for calls, video or photos should have these.",
              path: "Settings › Privacy & Security › Microphone, then Camera",
              actions: ["Turn off any app you don't use for calls, video or photos."]),
        .init(id: "motion", title: "Motion & Fitness", symbol: "figure.walk",
              why: "Shows when you walk, drive or sleep, which reveals your daily routine.",
              path: "Settings › Privacy & Security › Motion & Fitness",
              actions: ["Keep it only for fitness and health apps you trust."]),
        .init(id: "tracking", title: "Tracking", symbol: "hand.raised",
              why: "Turning this off tells every app not to track you across other companies' apps and websites.",
              path: "Settings › Privacy & Security › Tracking",
              actions: ["Turn off Allow Apps to Request to Track."]),
        .init(id: "paste", title: "Pasting", symbol: "doc.on.clipboard",
              why: "Apps can ask to read what you copied, which may include passwords or addresses.",
              path: "Settings › Apps › [an app] › Paste from Other Apps",
              actions: ["Set Ask for apps you don't fully trust."]),
        .init(id: "privacy-report", title: "App Privacy Report", symbol: "chart.bar.doc.horizontal",
              why: "Shows which apps actually used your location, camera, microphone and contacts in the last 7 days, and which websites they contacted.",
              path: "Settings › Privacy & Security › App Privacy Report",
              actions: ["Turn it on if it's off, then come back in a few days.", "Look for apps using things you didn't expect, and remove their access."]),
    ]

    private static func privacy(_ anchor: String) -> String { MacSignalCatalogue.Pane.privacy(anchor) }

    /// The Mac's areas. Most System Settings pages open directly on a Mac.
    static let macSteps: [CheckUpStep] = [
        .init(id: "mac-device-management", title: "Device Management", symbol: "gearshape.2",
              why: "A profile here can let an organisation manage this Mac, send your internet traffic through its servers, or read connections that are meant to be private.",
              path: "System Settings › General › Device Management",
              actions: ["Select each profile you don't recognise and click the minus button to remove it.",
                        "Keep ones your work or school set up with you."],
              pane: "com.apple.Profiles-Settings.extension"),
        .init(id: "mac-filevault", title: "Encrypt your Mac", symbol: "lock.doc",
              why: "FileVault keeps your files unreadable without your password if your Mac is lost or stolen.",
              path: "System Settings › Privacy & Security › FileVault",
              actions: ["Turn on FileVault if it's off.", "Keep the recovery key somewhere other than this Mac."],
              pane: privacy("FileVault"), counts: false, hint: "Keep your files unreadable to others"),
        .init(id: "mac-lock", title: "Lock your Mac", symbol: "lock",
              why: "A password straight after sleep keeps your Mac private when you step away.",
              path: "System Settings › Lock Screen",
              actions: ["Set Require password after screen saver begins or display is turned off to Immediately.", "Set the display to turn off after 5 minutes or less when inactive."],
              pane: "com.apple.Lock-Screen-Settings.extension", counts: false, hint: "Require a password straight away"),
        .init(id: "mac-apple-account", title: "Protect your Apple Account", symbol: "person.badge.key",
              why: "Your Apple Account can hold your photos, messages and backups. Two-factor authentication protects it even if your password leaks.",
              path: "System Settings › [your name] › Sign-In & Security",
              actions: ["Turn on Two-Factor Authentication.", "Add a trusted phone number you can always reach."],
              pane: "com.apple.systempreferences.AppleIDSettings", counts: false, hint: "Two-factor and a trusted number"),
        .init(id: "mac-find", title: "Be able to find your Mac", symbol: "location.magnifyingglass",
              why: "If you lose your Mac, you can see where it is, lock it or erase it from another device.",
              path: "System Settings › [your name] › iCloud › See All › Find My Mac",
              actions: ["Turn on Find My Mac.", "Turn on Find My network, so it can be found even when it's offline."],
              pane: "com.apple.systempreferences.AppleIDSettings", counts: false, hint: "Find it even when it's offline"),
        .init(id: "mac-social", title: "Social media apps", symbol: "person.2.wave.2",
              why: "Social apps can learn a lot from what they're allowed to reach, and from what other apps and websites share with them.",
              path: "System Settings › Privacy & Security",
              actions: ["In each permission, turn off social apps that don't need it.",
                        "In each app or website, open its privacy and ad settings and turn off what you don't want.",
                        "On Facebook and Instagram, look in Accounts Center or Meta Account settings for Your activity off Meta technologies and Ad preferences. Names can change, and some options aren't offered everywhere."],
              pane: MacSignalCatalogue.Pane.privacy, counts: false, hint: "What they can reach and share"),
        .init(id: "mac-updates", title: "Keep macOS updated", symbol: "arrow.down.circle",
              why: "Updates close the holes that spyware uses to get in. It's the single best protection there is.",
              path: "System Settings › General › Software Update",
              actions: ["Click the ⓘ next to Automatic Updates and turn everything on.", "If an update is waiting, install it now."],
              pane: "com.apple.Software-Update-Settings.extension"),
        .init(id: "mac-passwords", title: "Check for leaked passwords", symbol: "key",
              why: "Apple's Passwords app warns you when a saved password has turned up in a known data leak. It checks without revealing your passwords, and this app sees nothing.",
              path: "Passwords app › Security",
              actions: ["Open the Passwords app and click Security.", "Change any password marked as leaked or reused."],
              app: ("Open Passwords", "com.apple.Passwords")),
        .init(id: "mac-lockdown", title: "Protection from targeted spyware", symbol: "lock.shield",
              why: "Lockdown Mode is Apple's strongest defence against rare, targeted spyware. Most people never need it; journalists, activists and officials should consider it.",
              path: "System Settings › Privacy & Security › Lockdown Mode",
              actions: ["If your work could make you a target, turn on Lockdown Mode.", "If Apple ever warns you of a targeted attack, follow its advice."],
              pane: privacy("LockdownMode")),
        .init(id: "mac-location", title: "Location", symbol: "location",
              why: "Your location shows where you live, work and spend time.",
              path: "System Settings › Privacy & Security › Location Services",
              actions: ["Turn off any app that doesn't need your location.", "Click Details next to System Services and turn off what you don't use."],
              pane: privacy("Privacy_LocationServices")),
        .init(id: "mac-contacts", title: "Contacts", symbol: "person.2",
              why: "Your contacts include other people's numbers and addresses, not just yours.",
              path: "System Settings › Privacy & Security › Contacts",
              actions: ["Turn off any app that doesn't need your contacts."],
              pane: privacy("Privacy_Contacts")),
        .init(id: "mac-calendars", title: "Calendars and Reminders", symbol: "calendar",
              why: "Calendars show your routine, and their account names often give away where you work.",
              path: "System Settings › Privacy & Security › Calendars, then Reminders",
              actions: ["Prefer Add Events Only for apps that just create events.", "Turn off access for apps you don't recognise."],
              pane: privacy("Privacy_Calendars")),
        .init(id: "mac-photos", title: "Photos", symbol: "photo.on.rectangle",
              why: "Full Photos access lets an app see every picture and where each one was taken.",
              path: "System Settings › Privacy & Security › Photos",
              actions: ["Choose Limited Access, or None for apps that never need photos."],
              pane: privacy("Privacy_Photos")),
        .init(id: "mac-camera-mic", title: "Camera and Microphone", symbol: "camera",
              why: "Only apps you use for calls, video or recording should have these.",
              path: "System Settings › Privacy & Security › Camera, then Microphone",
              actions: ["Turn off any app you don't use for calls, video or recording."],
              pane: privacy("Privacy_Camera")),
        .init(id: "mac-screen", title: "Screen and audio recording", symbol: "rectangle.dashed.badge.record",
              why: "These apps can see everything on your screen, including other apps' windows and messages.",
              path: "System Settings › Privacy & Security › Screen & System Audio Recording",
              actions: ["Keep only apps you use for screen sharing or recording."],
              pane: privacy("Privacy_ScreenCapture")),
        .init(id: "mac-input", title: "Input monitoring", symbol: "keyboard",
              why: "Apps here can see every key you press, in every app.",
              path: "System Settings › Privacy & Security › Input Monitoring",
              actions: ["Remove any app you don't recognise or no longer use."],
              pane: privacy("Privacy_ListenEvent")),
        .init(id: "mac-accessibility", title: "Accessibility control", symbol: "accessibility",
              why: "Apps here can control your Mac and read what's on screen.",
              path: "System Settings › Privacy & Security › Accessibility",
              actions: ["Keep only apps you trust and actually use for this."],
              pane: privacy("Privacy_Accessibility")),
        .init(id: "mac-files", title: "Full Disk Access", symbol: "internaldrive",
              why: "Apps here can read almost every file on your Mac, including mail and messages.",
              path: "System Settings › Privacy & Security › Full Disk Access",
              actions: ["Remove any app that doesn't truly need it, such as old backup or cleaning tools."],
              pane: privacy("Privacy_AllFiles")),
        .init(id: "mac-bluetooth", title: "Bluetooth", symbol: "dot.radiowaves.left.and.right",
              why: "Bluetooth lets apps see devices around you, often named after their owners.",
              path: "System Settings › Privacy & Security › Bluetooth",
              actions: ["Turn off any app that doesn't connect to a device of yours."],
              pane: privacy("Privacy_Bluetooth")),
        .init(id: "mac-paste", title: "Pasting", symbol: "doc.on.clipboard",
              why: "Apps can read what you copied, which may include passwords or addresses.",
              path: "System Settings › Privacy & Security › Paste from Other Apps",
              actions: ["Set Ask for apps you don't fully trust."],
              pane: privacy("Privacy_Pasteboard")),
        .init(id: "mac-sharing", title: "Your Mac's name", symbol: "laptopcomputer",
              why: "Your Mac's name is visible to every app and to other devices on your network.",
              path: "System Settings › General › About, then General › Sharing",
              actions: ["In About, click Name and type a name that doesn't include yours, such as \"MacBook\".",
                        "In Sharing, scroll to Local hostname at the bottom, click Edit and change it to match."],
              pane: MacSignalCatalogue.Pane.about,
              secondPane: ("Open Sharing", MacSignalCatalogue.Pane.sharing)),
        .init(id: "mac-login-items", title: "Login items", symbol: "power",
              why: "These apps start every time you log in and can run in the background all day.",
              path: "System Settings › General › Login Items & Extensions",
              actions: ["Turn off anything you don't need running all the time."],
              pane: "com.apple.LoginItems-Settings.extension"),
    ]
}
