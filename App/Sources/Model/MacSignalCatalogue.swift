// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// The Mac's findings. Same wording rules as the iOS catalogue: plain words, "could" rather than
/// "will", and every entry says what an app learns, why the system allows it, how long it lasts
/// and what to do. Where a System Settings page opens directly, the fix carries its pane id
/// (tested on macOS 27, docs/MACOS-PLAN.md).
enum MacSignalCatalogue {
    enum Pane {
        static let privacy = "com.apple.settings.PrivacySecurity.extension"
        static let users = "com.apple.Users-Groups-Settings.extension"
        static let sharing = "com.apple.Sharing-Settings.extension"
        /// General › About, where the Mac's name is set (it moved out of Sharing).
        static let about = "com.apple.SystemProfiler.AboutExtension"
        static let language = "com.apple.Localization-Settings.extension"
        static let keyboard = "com.apple.Keyboard-Settings.extension"
        static let appearance = "com.apple.Appearance-Settings.extension"
        static let accessibility = "com.apple.Accessibility-Settings.extension"
        static let sound = "com.apple.Sound-Settings.extension"
        static let network = "com.apple.Network-Settings.extension"
        static let wifi = "com.apple.wifi-settings-extension"
        static let desktopDock = "com.apple.Desktop-Settings.extension"
        static let storage = "com.apple.settings.Storage"
        static func privacy(_ anchor: String) -> String { "\(privacy)?\(anchor)" }
    }

    static let restart = Fix.guided("Once a week is enough. Apps can no longer link you by your last restart time, and a restart also clears some kinds of spyware that only live in memory.", [
        "Choose Apple menu › Restart.",
    ])

    static let list: [SignalDefinition] = person + thisMac + passive + apps + reused + permission

    // MARK: You

    static let person: [SignalDefinition] = [
        .init(id: "mac-full-name", section: .person, title: "Your full name",
              reveals: "The full name on your Mac account, exactly as you typed it when you set the Mac up. Any app can read it and put a real name to everything else it knows.",
              why: "So apps can fill in your name, for example as the author of a document.",
              persistence: .untilYouChangeIt, severity: .high,
              fix: .settings("Use a first name only, a nickname or initials on your Mac account. It doesn't change your Apple Account.", pane: Pane.users, [
                  "Open System Settings › Users & Groups.",
                  "Control-click your account, then choose Advanced Options.",
                  "Change Full Name and click OK. Leave Account Name and Home folder as they are.",
              ])),
        .init(id: "mac-account-name", section: .person, title: "Your account name",
              reveals: "The short name of your Mac account, which is also the name of your home folder. It's often your first name or initials.",
              why: "It's part of the folder path apps use to save files.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .leaveIt("Changing it means renaming your home folder, which can break apps. Most people should leave it.")),
        .init(id: "mac-admin", section: .person, title: "Administrator or not",
              reveals: "Whether your account can install software and change settings for the whole Mac.",
              why: "So apps can tell whether you can approve system changes.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .leaveIt("Nothing to change for privacy. A separate everyday account without admin rights is safer, but that's a security choice.")),
    ]

    // MARK: This Mac

    static let thisMac: [SignalDefinition] = [
        .init(id: "mac-serial", section: .identity, title: "Serial number",
              reveals: "Your Mac's serial number. It's unique to this Mac and never changes, so any app can use it to recognise you for as long as you own it.",
              why: "So apps can check warranty or licences. Apple's rules forbid using it to track people, but nothing technically stops an app reading it.",
              persistence: .permanent, severity: .high,
              fix: .onlyApple("No setting hides it, and erasing the Mac doesn't change it. Apple needs to close this.")),
        .init(id: "mac-hardware-id", section: .identity, title: "Hardware ID",
              reveals: "A second permanent code unique to this Mac. Like the serial number, it identifies you across every app forever.",
              why: "It's a system ID for this machine that the system makes readable.",
              persistence: .permanent, severity: .high,
              fix: .onlyApple("No setting hides it, and erasing the Mac doesn't change it. Apple needs to close this.")),
        .init(id: "mac-model", section: .identity, title: "Model and chip",
              reveals: "Your exact Mac model, its chip and how much memory it has. It narrows down who you are and roughly what you paid.",
              why: "So apps can adjust to your hardware.",
              persistence: .hardware, severity: .low,
              fix: .onlyApple("This comes with the hardware. There's nothing to change.")),
        .init(id: "mac-system-version", section: .identity, title: "System version",
              reveals: "Exactly which macOS version and build you run.",
              why: "So apps can turn features on or off.",
              persistence: .untilUpdate, severity: .low,
              fix: .guided("Keeping up to date puts you in the biggest crowd and gets you Apple's privacy fixes.", [
                  "Open System Settings › General › Software Update.",
                  "Turn on automatic updates.",
              ])),
        .init(id: "mac-computer-name", section: .identity, title: "Computer name",
              reveals: "Your Mac's name and its name on the network, often something like \"Sam's MacBook Pro\". That hands over a first name, and nearby devices on your network see it too.",
              why: "So you can tell your Macs apart when sharing files or using AirDrop.",
              persistence: .untilYouChangeIt, severity: .high,
              fix: .settings("Give your Mac a name that doesn't include yours, such as \"MacBook\".", pane: Pane.about, [
                  "Open System Settings › General › About, click Name and type the new name.",
                  "Then open General › Sharing, scroll to Local hostname, click Edit and change it to match.",
              ])),
        .init(id: "mac-graphics", section: .identity, title: "Graphics chip",
              reveals: "Your graphics chip and what it can do, which points to how new your Mac is.",
              why: "So games and graphics apps can pick the right quality.",
              persistence: .hardware, severity: .low,
              fix: .onlyApple("This comes with the hardware. There's nothing to change.")),
    ]

    // MARK: Seen without asking

    static let passive: [SignalDefinition] = [
        .init(id: "mac-boot-time", section: .system, title: "Last restart",
              reveals: "The exact second your Mac last started, and how long it's been running. Few Macs share it, so it can link you across apps until you restart.",
              why: "So apps can measure time that has passed.",
              persistence: .untilRestart, severity: .high, fix: restart),
        .init(id: "mac-battery", section: .system, title: "Battery level",
              reveals: "Your exact charge and whether you're plugged in. Two apps opened minutes apart see almost the same number, which can link them.",
              why: "So apps can put off heavy work when the battery is low.",
              persistence: .changesOften, severity: .low,
              fix: .leaveIt("Not worth changing. It's a small detail.")),
        .init(id: "disk-total", section: .storage, title: "Total storage",
              reveals: "Your storage size (512 GB, 1 TB…).",
              why: "So apps can plan downloads.",
              persistence: .hardware, severity: .low,
              fix: .onlyApple("This comes with the hardware. There's nothing to change.")),
        .init(id: "disk-free", section: .storage, title: "Free space, to the byte",
              reveals: "Exactly how much space is free. It changes slowly, so two apps that read the same number at about the same time can tell they're on the same Mac.",
              why: "So apps can check there's room before downloading.",
              persistence: .changesOften, severity: .high,
              fix: .onlyApple("No setting rounds it off. Apple could give apps a rounded number instead.")),
        .init(id: "mac-drives", section: .storage, title: "Connected drives",
              reveals: "The names of every connected drive and disk image. Names like \"Sam's Backup\" or a work drive say who you are and where you work.",
              why: "So apps can open and save files on them.",
              persistence: .changesOften, severity: .medium,
              fix: .guided("Eject drives you're not using, and rename drives that carry your name.", [
                  "In Finder, click the eject button next to a drive you're not using.",
                  "To rename a drive, select it in Finder, press Return and type a new name.",
              ])),
        .init(id: "mac-screens", section: .display, title: "Your screens",
              reveals: "Every screen connected, with its name, size and sharpness. An external monitor's model makes your setup rarer.",
              why: "So apps can lay out windows correctly.",
              persistence: .changesOften, severity: .low,
              fix: .leaveIt("Not worth changing. It's a small detail.")),
        .init(id: "mac-audio", section: .audio, title: "Sound devices",
              reveals: "Every speaker, headset and microphone by name. Names like \"Sam's AirPods\" give away a first name, and virtual devices reveal apps you use, such as video-call apps.",
              why: "So apps can play and record sound on the right device.",
              persistence: .changesOften, severity: .medium,
              fix: .settings("Rename headphones that carry your name.", pane: "com.apple.BluetoothSettings", [
                  "Open System Settings › Bluetooth.",
                  "Click ⓘ next to your headphones, then change the name.",
              ])),
        .init(id: "mac-usb", section: .audio, title: "Connected accessories",
              reveals: "Everything plugged into your Mac by USB, by name. A connected phone, a work security key or a particular keyboard can all show up.",
              why: "So apps can work with accessories.",
              persistence: .changesOften, severity: .medium,
              fix: .leaveIt("Unplug what you don't need. Names come from the maker, so there's little else to change.")),
        .init(id: "mac-languages", section: .language, title: "Preferred languages",
              reveals: "Your languages, in order. An unusual mix is rare and can hint at where you're from.",
              why: "So apps can show the right language.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .settings("Remove languages you don't use. The fewer unusual choices, the more you blend in.", pane: Pane.language, [
                  "Open System Settings › General › Language & Region.",
                  "Select a language you don't use and click −.",
              ])),
        .init(id: "mac-input-sources", section: .language, title: "Keyboards",
              reveals: "Every keyboard language you've added. It shows which languages you write in.",
              why: "So apps can adapt text input.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .settings("Remove keyboards you don't use.", pane: Pane.keyboard, [
                  "Open System Settings › Keyboard.",
                  "Under Text Input, click Edit.",
                  "Select a keyboard you don't use and click −.",
              ])),
        .init(id: "mac-region", section: .language, title: "Region and formats",
              reveals: "Your region, calendar, units, first day of the week and currency. Every change from the default makes you rarer.",
              why: "So dates, numbers and prices show the way you expect.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .settings("Set back formats you changed but don't need.", pane: Pane.language, [
                  "Open System Settings › General › Language & Region.",
                  "Check Region, Calendar, Temperature and First day of week.",
              ])),
        .init(id: "mac-timezone", section: .language, title: "Time zone",
              reveals: "Your time zone, close to your city. A VPN doesn't hide it.",
              why: "So times show correctly.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .leaveIt("Setting the time zone by hand hides it, but breaks reminders and meetings when you travel. Most people should leave it.")),
        .init(id: "mac-accessibility", section: .accessibility, title: "Accessibility features",
              reveals: "Which accessibility features are on, such as VoiceOver, Reduce Motion or Increase Contrast. Some can hint at a disability, which is sensitive.",
              why: "So apps can adapt to what you need.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .leaveIt("These settings are there for you. Keep the ones you need; we're only pointing out that apps can see them.")),
        .init(id: "mac-appearance", section: .accessibility, title: "Light or dark, and accent colour",
              reveals: "Whether you use light or dark mode, and the accent colour you picked.",
              why: "So apps match your look.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .leaveIt("Not worth changing. It's a small detail.")),
        .init(id: "mac-clipboard", section: .clipboard, title: "What's on the clipboard",
              reveals: "How many times anything has been copied, and what kind of thing is on the clipboard now. The kinds can even reveal which app you copied from. Two apps that read the same count can link you.",
              why: "So apps know when to enable Paste.",
              persistence: .changesOften, severity: .medium,
              fix: .settings("macOS can ask before an app reads what you copied. Set apps you don't fully trust to Ask.", pane: Pane.privacy("Privacy_Pasteboard"), [
                  "Open System Settings › Privacy & Security › Paste from Other Apps.",
                  "Set apps you don't fully trust to Ask.",
              ])),
        .init(id: "mac-connection", section: .network, title: "Connection type",
              reveals: "Whether you're on Wi-Fi, Ethernet or a phone's hotspot.",
              why: "So apps can save data on expensive connections.",
              persistence: .changesOften, severity: .low,
              fix: .leaveIt("Not worth changing. It's a small detail.")),
        .init(id: "mac-hardware-addresses", section: .network, title: "Network hardware addresses",
              reveals: "The permanent hardware addresses of your Mac's network ports. They're unique to this Mac and don't change.",
              why: "Networks use them to deliver data to the right machine.",
              persistence: .permanent, severity: .high,
              fix: .settings("Wi-Fi can use a private address instead. Wired ports can't.", pane: Pane.wifi, [
                  "Open System Settings › Wi-Fi.",
                  "Click Details next to your network.",
                  "Set Private Wi-Fi address to Rotating or Fixed.",
              ])),
        .init(id: "mac-dns", section: .network, title: "Router and network names",
              reveals: "Your router's address, the servers that look up websites for you, and any network names, which often reveal your employer or internet provider.",
              why: "So apps can connect to the internet and to work services.",
              persistence: .changesOften, severity: .medium,
              fix: .leaveIt("These come from the network you're on. A VPN hides some of them from websites, but not from apps.")),
        .init(id: "vpn", section: .network, title: "VPN in use",
              reveals: "Whether a VPN is running. A VPN hides your address from websites, but apps can still see that you use one.",
              why: "It's visible in the network settings any app can read.",
              persistence: .changesOften, severity: .low,
              fix: .leaveIt("Nothing to fix: a VPN can't hide that it's on. Keep using it if it helps you.")),
        .init(id: "mac-fonts", section: .fontsVoices, title: "Installed fonts",
              reveals: "Every font on your Mac, often 500 or more. Fonts that come with apps like office or design software reveal what you use, and your exact set is close to unique.",
              why: "So apps can show text correctly.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .guided("Remove fonts you added but don't use.", [
                  "Open the Font Book app.",
                  "Click My Fonts in the sidebar.",
                  "Select fonts you don't need and press Delete.",
              ])),
    ]

    // MARK: Apps on this Mac

    static let apps: [SignalDefinition] = [
        .init(id: "mac-installed-apps", section: .apps, title: "Every app on this Mac",
              reveals: "A full list of the apps you have installed. There's no limit on a Mac, unlike on a phone. Your apps can reveal your work, health, faith, dating life and money.",
              why: "So apps can open files and links with the right app.",
              persistence: .untilYouChangeIt, severity: .high,
              // No setting hides the list, so this isn't in the score: deleting apps shortens it
              // but never makes it go away, and the score must only promise what a scan can see.
              fix: Fix(level: .onlyApple, summary: "No setting hides your app list; only Apple could stop apps reading it. Deleting apps you no longer use keeps it short: an app you've deleted can't give you away.", steps: [
                  "Open Finder › Applications.",
                  "Drag apps you no longer use to the Bin (Trash).",
              ])),
        .init(id: "mac-running-apps", section: .apps, title: "What you're running right now",
              reveals: "Every app open right now and about a thousand background programs, by name. Together they show what you're doing and what software you use, minute by minute.",
              why: "So apps can work together and switch to each other.",
              persistence: .changesOften, severity: .high,
              fix: .onlyApple("No setting hides this. Apple could stop apps seeing what else is running.")),
        .init(id: "mac-default-browser", section: .apps, title: "Default browser",
              reveals: "Which browser opens your links.",
              why: "So apps can open links the way you expect.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .leaveIt("Not worth changing. It's a small detail.")),
    ]

    // MARK: Shared with iOS (wording that already fits), with Mac fixes

    static let reused: [SignalDefinition] = {
        let byID = Dictionary(uniqueKeysWithValues: (SignalCatalogue.passive + SignalCatalogue.advanced).map { ($0.id, $0) })
        var out: [SignalDefinition] = []
        for id in ["storefront", "install-date", "first-download"] { if let d = byID[id] { out.append(d) } }
        if let reinstall = byID["reinstall-memory"] {
            out.append(reinstall.with(fix: .onlyApple("Deleting the app doesn't clear it, and nor does a reinstall. Apple could limit this.")))
        }
        return out
    }()

    // MARK: Seen once you allow it

    static let permission: [SignalDefinition] = {
        let fixes: [SignalSection: Fix] = [
            .location: .settings("Give each app the least it needs, and turn it off for apps that don't need your location.", pane: Pane.privacy("Privacy_LocationServices"), [
                "Open System Settings › Privacy & Security › Location Services.",
                "Turn off any app that doesn't need your location.",
            ]),
            .camera: .settings("Only apps you use for calls and video should have the camera.", pane: Pane.privacy("Privacy_Camera"), [
                "Open System Settings › Privacy & Security › Camera.",
                "Turn off any app you don't use for calls or video.",
            ]),
            .bluetooth: .settings("Only apps that connect to an accessory need Bluetooth.", pane: Pane.privacy("Privacy_Bluetooth"), [
                "Open System Settings › Privacy & Security › Bluetooth.",
                "Turn off any app that doesn't work with an accessory you own.",
            ]),
            .contacts: .settings("Only apps that really need your contacts should have them.", pane: Pane.privacy("Privacy_Contacts"), [
                "Open System Settings › Privacy & Security › Contacts.",
                "Turn off any app that doesn't need your contacts.",
            ]),
            .photos: .settings("Give apps only the photos they need.", pane: Pane.privacy("Privacy_Photos"), [
                "Open System Settings › Privacy & Security › Photos.",
                "For each app, choose Limited Access or None.",
            ]),
            .calendars: .settings("Most apps only need to add events. Add Events Only lets them do that without reading your calendar.", pane: Pane.privacy("Privacy_Calendars"), [
                "Open System Settings › Privacy & Security › Calendars.",
                "For each app, choose Add Events Only, or None.",
            ]),
            .reminders: .settings("Only to-do apps need your reminders.", pane: Pane.privacy("Privacy_Reminders"), [
                "Open System Settings › Privacy & Security › Reminders.",
                "Turn off any app that isn't a to-do app you use.",
            ]),
        ]
        return SignalCatalogue.permission.compactMap { d in
            guard let fix = fixes[d.section] else { return nil }
            return d.with(fix: fix)
        }
    }()
}

extension SignalDefinition {
    func with(fix: Fix) -> SignalDefinition {
        SignalDefinition(id: id, section: section, title: title, reveals: reveals, why: why,
                         persistence: persistence, severity: severity, fix: fix, status: status)
    }
}
