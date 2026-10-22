// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// How serious a finding is, said plainly: a level, what it lets someone do, and for the clues
/// worth a look, a concrete "in practice" line. Calm and specific; never "spyware" or "hacked".
enum SignalImpact {
    enum Level: String { case serious = "Serious", worthKnowing = "Worth knowing", minor = "Minor" }

    static func level(_ s: Severity) -> Level {
        switch s {
        case .high: .serious
        case .medium: .worthKnowing
        case .low: .minor
        }
    }

    /// What the clue lets someone do, by how much it narrows you down.
    static func reach(_ s: Severity) -> String {
        switch s {
        case .high: "Enough on its own to tell this device apart from almost every other, so apps and the companies behind them can recognise you."
        case .medium: "Narrows down who you are. Combined with two or three other clues, it can single out this device."
        case .low: "Shared by many devices, so it says little on its own. It only matters alongside other clues."
        }
    }

    /// Why how long it lasts matters.
    static func lasting(_ p: Persistence) -> String {
        switch p {
        case .untilRestart: "It stays the same until you restart, so it can link what you do across apps in the meantime."
        case .untilVendorAppsDeleted: "It stays until you delete every app from that company, so they can follow you for months."
        case .untilReinstall: "It stays until you delete and reinstall the app."
        case .untilErase: "It stays until you erase the device: for most people, the life of the device."
        case .hardware: "It's fixed for this model, so it can't be changed, only blended in with others like it."
        case .untilYouChangeIt: "It stays until you change it, which you can do now."
        case .changesOften: "It changes often, which makes it weaker for tracking."
        case .followsAppleAccount: "It follows your Apple Account, even onto a new device."
        case .untilUpdate: "It stays until you update the system."
        case .permanent: "It never changes, even if you erase the device, so it can recognise you for as long as you own it."
        }
    }

    /// A concrete line for the clues worth a look.
    static let inPractice: [String: String] = [
        "idfv": "Every app from one company can match up what you do in each of them, and keep doing so until all its apps are gone.",
        "boot-time": "Two unrelated apps that both read it can work out they're on the same device, without any account or login.",
        "disk-free": "Your free space to the byte is almost unique and changes slowly, so ad companies use it to match you across apps within the same hour.",
        "volume-created": "The moment this device was set up is unique to it and survives reinstalls, so it works like a hidden serial number.",
        "reinstall-memory": "Deleting the app and installing it again doesn't make you a new person to it: it can tell it's you.",
        "mac-full-name": "Any app can put your real name next to everything else it collects, without ever asking.",
        "mac-serial": "The serial number never changes, so it can tie together everything any app on this Mac ever learns about you.",
        "mac-hardware-id": "Like the serial number, it's permanent and unique, and it survives erasing the Mac.",
        "mac-computer-name": "It often contains your first name, and other devices on the same Wi-Fi can see it too.",
        "mac-boot-time": "Two unrelated apps that both read it can work out they're on the same Mac.",
        "mac-hardware-addresses": "These addresses identify your Mac's network hardware and rarely change, so they can follow the Mac between networks.",
        "mac-installed-apps": "Your list of apps can reveal your work, health, faith, dating life or politics, and together it's close to unique.",
        "mac-running-apps": "It shows what you're doing right now, such as which messaging or banking app is open.",
        "motion-activity": "Walking, driving and sleeping times reveal your routine: when you leave home, commute and go to bed.",
        "loc-where": "A precise location reveals your home and workplace within metres.",
        "cal-accounts": "Calendar account names often include your work email, which names your employer.",
        "photos-home-work": "Where most of your photos were taken gives away where you live and work.",
        "device-name": "A device name that includes your first name hands it to every app and to nearby devices.",
        "accessibility": "A service here can read everything on screen, including messages and passwords as you type them.",
        "android-id": "Deleting the app and installing it again doesn't make you a new person to its company: the code stays the same.",
        "watch-several": "One app with several of these can see your screen, read your messages and lock you out.",
    ]
}
