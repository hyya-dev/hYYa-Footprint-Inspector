// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// Every signal we know how to describe, keyed by id.
///
/// Wording rules: calm, plain English, "could" rather than "will". Every entry says
/// what an app learns, why iOS allows it, how long it lasts and what the user can do.
enum SignalCatalogue {
    /// This platform's definitions, in display order.
    static let list: [SignalDefinition] = {
        #if os(macOS)
        MacSignalCatalogue.list
        #else
        passive + advanced + permission
        #endif
    }()

    static let all: [String: SignalDefinition] = {
        var map: [String: SignalDefinition] = [:]
        for d in list { map[d.id] = d }
        return map
    }()

    static func definition(_ id: String) -> SignalDefinition? { all[id] }

    static func definitions(in section: SignalSection) -> [SignalDefinition] {
        list.filter { $0.section == section }
    }
}

// MARK: - Shared fix wording

extension Fix {
    static let restart = Fix.guided("Once a week is enough. Apps can no longer link you by your last restart time, and a restart also clears some kinds of spyware that only live in memory.", [
        "Press and hold the side or top button and either volume button until the slider appears. On a device with a Home button, hold the side or top button alone.",
        "Drag the slider to turn the device off.",
        "Wait a few seconds, then hold the side or top button until the Apple logo appears.",
    ])

    static let rename = Fix.guided("Give your device a name that doesn't include your own.", [
        "Open Settings › General › About.",
        "Tap Name.",
        "Choose something generic, such as the model name.",
    ])

    static let languageRegion = Fix.guided("Remove languages and custom formats you don't use. The fewer unusual choices, the more you blend in.", [
        "Open Settings › General › Language & Region.",
        "Under Preferred Languages, swipe left on any language you don't use.",
        "Check the formats below (calendar, temperature, first day of week). Set back any you changed but don't need.",
    ])

    static let keyboards = Fix.guided("Remove keyboards you don't use. Each extra keyboard makes your device easier to tell apart.", [
        "Open Settings › General › Keyboard › Keyboards.",
        "Tap Edit.",
        "Remove the keyboards you no longer type with.",
    ])

    static let accessibilityChoice = Fix.leaveIt("These settings are there for you. Keep the ones you need; we're only pointing out that apps can see them.")
}

// MARK: - Passive

extension SignalCatalogue {
    static let passive: [SignalDefinition] = [
        // Device identity
        .init(id: "idfv", section: .identity, title: "Code shared by one company's apps",
              reveals: "A long code that's the same in every app from one company on this device. That company can link everything you do across its apps.",
              why: "So one developer's apps can share settings and spot abuse.",
              persistence: .untilVendorAppsDeleted, severity: .high,
              fix: .guided("The code resets only when every app from that company is deleted.", [
                  "Find the other apps you have from the same developer.",
                  "Delete all of them. The next install gets a new code.",
              ])),
        .init(id: "device-name", section: .identity, title: "Device name",
              reveals: "Usually just the model name. A few apps with Apple's special permission can still read the name you chose, which often includes your first name.",
              why: "So you can tell your devices apart when sharing or syncing.",
              persistence: .untilYouChangeIt, severity: .low, fix: .rename),
        .init(id: "os-version", section: .identity, title: "System version",
              reveals: "Exactly which system version you run.",
              why: "So apps can turn features on or off.",
              persistence: .untilUpdate, severity: .low,
              fix: .guided("Keeping up to date puts you in the biggest crowd and gets you Apple's privacy fixes.", [
                  "Open Settings › General › Software Update.",
                  "Turn on Automatic Updates.",
              ])),
        .init(id: "os-build", section: .identity, title: "System build number",
              reveals: "The exact software build. It shows whether you run test (beta) versions or a quick security update.",
              why: "So developers can match problem reports to the right software.",
              persistence: .untilUpdate, severity: .medium,
              fix: .guided("People testing early (beta) versions stand out. If you don't need them, switch back to regular updates.", [
                  "Open Settings › General › Software Update › Beta Updates.",
                  "Choose Off, then install the next regular update.",
              ])),
        .init(id: "model-id", section: .identity, title: "Exact model",
              reveals: "The precise model of your device, down to its internal code name.",
              why: "So apps can tune performance for your hardware.",
              persistence: .hardware, severity: .low, fix: .onlyApple()),
        .init(id: "kernel-version", section: .identity, title: "Software core version",
              reveals: "The exact version of the software at the heart of your device, including the day it was built.",
              why: "Mostly used to track down bugs.",
              persistence: .untilUpdate, severity: .low, fix: .onlyApple()),

        // System
        .init(id: "cpu-ram", section: .system, title: "Processor and memory",
              reveals: "How powerful your device is: how many processor cores and how much memory it has.",
              why: "So apps can size their work to your hardware.",
              persistence: .hardware, severity: .low, fix: .onlyApple()),
        .init(id: "boot-time", section: .system, title: "Last restart",
              reveals: "The exact second your device last started. Few devices share it, so it can link you across apps until you restart.",
              why: "So apps can measure time that has passed.",
              persistence: .untilRestart, severity: .high, fix: .restart),
        .init(id: "low-power", section: .system, title: "Low Power Mode",
              reveals: "Whether Low Power Mode is on.",
              why: "So apps can do less work and save your battery.",
              persistence: .changesOften, severity: .low, fix: .leaveIt("Not worth changing. It's a small detail.")),
        .init(id: "battery", section: .system, title: "Battery level",
              reveals: "Your exact charge and whether you're charging. Two apps opened minutes apart see almost the same number, which can link them.",
              why: "So apps can put off heavy work when the battery is low.",
              persistence: .changesOften, severity: .low, fix: .onlyApple()),
        .init(id: "thermal", section: .system, title: "Device temperature",
              reveals: "Whether the device is running warm.",
              why: "So apps can ease off and avoid overheating.",
              persistence: .changesOften, severity: .low, fix: .onlyApple()),

        // Storage
        .init(id: "disk-total", section: .storage, title: "Total storage",
              reveals: "Your storage size (128 GB, 256 GB…).",
              why: "So apps can plan downloads.",
              persistence: .hardware, severity: .low, fix: .onlyApple()),
        .init(id: "disk-free", section: .storage, title: "Free space, to the byte",
              reveals: "Exactly how much space is free. It changes slowly, so two apps that read the same number at about the same time can tell they're on the same device.",
              why: "So apps can check there's room before downloading.",
              persistence: .changesOften, severity: .high, fix: .onlyApple()),
        .init(id: "volume-created", section: .storage, title: "When this device was set up",
              reveals: "The exact second this device was set up or last erased. Hardly any other device shares it, and it stays the same for years.",
              why: "It's a side effect of how storage works. There's no good reason for apps to see it.",
              persistence: .untilErase, severity: .high,
              fix: .onlyApple("Erasing the device resets it, but that's not a real fix. Apple needs to hide this."),
              status: .stillOpen),

        // Display
        .init(id: "screen", section: .display, title: "Screen details",
              reveals: "Your screen's size, sharpness, smoothness and colours. Together they point to your model, and to whether Display Zoom is on.",
              why: "So apps can lay out and draw correctly.",
              persistence: .hardware, severity: .low, fix: .onlyApple()),
        .init(id: "brightness", section: .display, title: "Brightness",
              reveals: "How bright your screen is right now, which hints at whether you're in a dark room or outdoors.",
              why: "So video and reading apps can adapt.",
              persistence: .changesOften, severity: .low, fix: .onlyApple()),
        .init(id: "text-size", section: .display, title: "Text size",
              reveals: "The text size you chose. A larger size can hint at eyesight needs.",
              why: "So apps can show text at the size you need.",
              persistence: .untilYouChangeIt, severity: .medium, fix: .accessibilityChoice),

        // Audio
        .init(id: "audio-route", section: .audio, title: "Connected headphones and speakers",
              reveals: "What's playing your audio, by name. Headphones are often named after their owner, such as \"Sam's AirPods\", which hands over a first name.",
              why: "So apps can route sound to the right place.",
              // Medium by default; the reader raises it to high when a name holds a first name.
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .guided("Rename your headphones so the name doesn't include yours.", [
                  "Connect your headphones, then open Settings.",
                  "Tap their name near the top, or go to Settings › Bluetooth and tap ⓘ next to them.",
                  "Tap Name and choose something generic, such as \"Headphones\".",
              ]),
              status: .stillOpen),
        .init(id: "volume", section: .audio, title: "Volume level",
              reveals: "Your exact volume. It changes slowly, so it helps link sessions together.",
              why: "So apps can warn about loud playback.",
              persistence: .changesOften, severity: .low, fix: .onlyApple()),
        .init(id: "other-audio", section: .audio, title: "Something else playing",
              reveals: "Whether you're listening to something in another app right now.",
              why: "So apps don't talk over your music.",
              persistence: .changesOften, severity: .low, fix: .onlyApple()),

        // Language, region, time
        .init(id: "languages", section: .language, title: "Preferred languages",
              reveals: "Your languages, in order. An unusual mix is rare and can hint at where you're from.",
              why: "So apps can show the right language.",
              persistence: .untilYouChangeIt, severity: .medium, fix: .languageRegion),
        .init(id: "keyboards", section: .language, title: "Keyboards",
              reveals: "Every keyboard language you've added. It shows which languages you write in.",
              why: "So apps can adapt text input.",
              persistence: .untilYouChangeIt, severity: .medium, fix: .keyboards),
        .init(id: "region", section: .language, title: "Region and formats",
              reveals: "Your region, calendar, clock style, first day of the week, units and currency. Every change from the default makes you rarer.",
              why: "So dates, numbers and prices show the way you expect.",
              persistence: .untilYouChangeIt, severity: .medium, fix: .languageRegion),
        .init(id: "timezone", section: .language, title: "Time zone",
              reveals: "Your time zone, close to your city. A VPN doesn't hide it, and a zone that doesn't match your region suggests you're travelling.",
              why: "So times show correctly.",
              persistence: .changesOften, severity: .medium,
              fix: .leaveIt("Setting the time zone by hand hides it, but breaks reminders and alarms when you travel. Most people should leave it.")),

        // Accessibility and appearance
        .init(id: "accessibility", section: .accessibility, title: "Accessibility features",
              reveals: "Which accessibility features are on, such as VoiceOver, Bold Text or Reduce Motion. Some can hint at a disability, which is sensitive.",
              why: "So apps can adapt to what you need.",
              persistence: .untilYouChangeIt, severity: .medium, fix: .accessibilityChoice),
        .init(id: "appearance", section: .accessibility, title: "Light or dark mode",
              reveals: "Whether you use light or dark mode, and higher contrast.",
              why: "So apps match your look.",
              persistence: .untilYouChangeIt, severity: .low, fix: .leaveIt("Not worth changing. It's a small detail.")),

        // Clipboard
        .init(id: "clip-count", section: .clipboard, title: "Copy counter",
              reveals: "A number that goes up every time anything is copied. Two apps that read the same number can link you.",
              why: "So apps know when to refresh a Paste button.",
              persistence: .untilRestart, severity: .medium, fix: .restart,
              status: .changed("Since version 27 it resets to zero when you restart.")),
        .init(id: "clip-kinds", section: .clipboard, title: "What's on the clipboard",
              reveals: "Whether you've copied text, a link, an image or a number, without the \"pasted from\" banner appearing. The contents themselves still trigger the banner.",
              why: "So apps can show or hide their Paste button.",
              persistence: .changesOften, severity: .low,
              fix: Fix(level: .inApp, summary: "You can clear the clipboard from here, and choose per app whether it may paste.", steps: [
                  "To stop an app pasting without asking: Settings › Apps › [the app] › Paste from Other Apps › Ask.",
              ])),

        // Motion sensors
        .init(id: "motion-raw", section: .motionSensors, title: "Motion sensors",
              reveals: "Live readings from the sensors that feel movement, turning and direction. They can reveal how you walk, hold the device or travel, and tiny factory flaws can single out your device.",
              why: "For games, screen rotation and fitness. Apple doesn't ask your permission for these.",
              persistence: .changesOften, severity: .medium, fix: .onlyApple(), status: .stillOpen),
        .init(id: "heading", section: .motionSensors, title: "Which way you're facing",
              reveals: "Your compass direction, without any location permission.",
              why: "For compass and map features.",
              persistence: .changesOften, severity: .medium, fix: .onlyApple(), status: .stillOpen),

        // Network
        .init(id: "connection", section: .network, title: "Connection type",
              reveals: "Whether you're on Wi-Fi or mobile data, and whether Low Data Mode is on.",
              why: "So apps can save data on expensive connections.",
              persistence: .changesOften, severity: .low, fix: .leaveIt("Not worth changing. It's a small detail.")),
        .init(id: "vpn", section: .network, title: "VPN in use",
              reveals: "Whether a VPN is running. A VPN hides your address from apps, but apps can still see that you use one.",
              why: "It's visible in the network settings any app can read.",
              persistence: .changesOften, severity: .medium,
              fix: .leaveIt("Nothing to fix: a VPN can't hide that it's on. Keep using it if it helps you.")),
        .init(id: "local-ip", section: .network, title: "Device addresses",
              reveals: "The network addresses your device uses on Wi-Fi and mobile data. Some can point to your home network.",
              why: "So apps can connect to nearby devices.",
              persistence: .changesOften, severity: .medium,
              fix: .guided("Private Wi-Fi addresses limit what networks see about you.", [
                  "Open Settings › Wi-Fi and tap ⓘ next to your network.",
                  "Set Private Wi-Fi Address to Rotating or Fixed.",
              ])),

        // Fonts and voices
        .init(id: "fonts", section: .fontsVoices, title: "Fonts",
              reveals: "Every font family on the device. Extra fonts you installed make your device stand out.",
              why: "So apps can show text correctly.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .guided("Remove fonts you added but don't use.", [
                  "Open Settings › General › Fonts.",
                  "Remove fonts or font apps you don't need.",
              ])),
        .init(id: "voices", section: .fontsVoices, title: "Downloaded voices",
              reveals: "The spoken voices on the device. Voices you chose to download hint at languages you use or accessibility needs.",
              why: "So apps can read text aloud.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .guided("Delete voices you don't use.", [
                  "Open Settings › Accessibility › Spoken Content › Voices.",
                  "Open a language and swipe left on voices you don't need.",
              ])),

        // Account and App Store
        .init(id: "storefront", section: .accountAndApp, title: "App Store country",
              reveals: "Which country's App Store you use. A VPN doesn't change it.",
              why: "So apps can show local prices and content.",
              persistence: .followsAppleAccount, severity: .low, fix: .onlyApple("Changing App Store country is a big step and rarely worth it.")),
        .init(id: "install-date", section: .accountAndApp, title: "When this app was installed",
              reveals: "When you installed this app.",
              why: "It's recorded on the app's own files.",
              persistence: .untilReinstall, severity: .low,
              fix: .leaveIt("Reinstalling resets it, which is rarely worth doing.")),
        .init(id: "first-download", section: .accountAndApp, title: "When your account first got this app",
              reveals: "When your Apple Account first downloaded this app. It survives deleting the app and moving to a new device.",
              why: "So developers can honour earlier purchases.",
              persistence: .followsAppleAccount, severity: .medium, fix: .onlyApple()),

        // Graphics and cellular
        .init(id: "gpu", section: .graphics, title: "Graphics chip",
              reveals: "Your graphics chip and what it can do, which points to how new your device is.",
              why: "So games and graphics apps can pick the right quality.",
              persistence: .hardware, severity: .low, fix: .onlyApple()),
        .init(id: "cellular", section: .graphics, title: "Mobile plans",
              reveals: "How many SIM or eSIM plans are active, and whether each is on 4G or 5G.",
              why: "So apps can adapt to your connection.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .guided("Remove eSIMs you no longer use.", [
                  "Open Settings › Mobile Service (or Cellular).",
                  "Tap a plan you don't use and choose Delete eSIM.",
              ])),

        // Security set-up
        .init(id: "passcode", section: .security, title: "Passcode and Face ID",
              reveals: "Whether a passcode is set, and whether you use Face ID or Touch ID.",
              why: "So apps can offer biometric sign-in.",
              persistence: .untilYouChangeIt, severity: .low,
              fix: .guided("A passcode protects everything else here. If yours isn't set, set one.", [
                  "Open Settings › Face ID & Passcode.",
                  "Tap Turn Passcode On.",
              ])),
        .init(id: "apple-pay", section: .security, title: "Apple Pay",
              reveals: "Whether Wallet has payment cards, and which card networks.",
              why: "So apps know whether to show an Apple Pay button.",
              persistence: .untilYouChangeIt, severity: .low, fix: .onlyApple()),
        .init(id: "mail-messages", section: .security, title: "Mail and Messages set up",
              reveals: "Whether the Mail app has an account and whether the device can send texts.",
              why: "So apps know whether to offer email or text sharing.",
              persistence: .untilYouChangeIt, severity: .low, fix: .onlyApple()),
        .init(id: "tracking", section: .security, title: "Tracking requests",
              reveals: "Whether apps are allowed to ask to track you. If tracking is allowed, apps can get a shared advertising code that follows you between them.",
              why: "It's Apple's \"Allow Apps to Request to Track\" switch.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .guided("Turn off tracking requests so every app is told no automatically.", [
                  "Open Settings › Privacy & Security › Tracking.",
                  "Turn off Allow Apps to Request to Track.",
              ])),
        .init(id: "managed", section: .security, title: "Managed by an organisation",
              reveals: "Whether a company or school controls settings on this device, as on a work device.",
              why: "So work apps can pick up their settings.",
              persistence: .untilYouChangeIt, severity: .medium,
              fix: .guided("If this is your own device and you don't recognise a profile, review it.", [
                  "Open Settings › General › VPN & Device Management.",
                  "Check each profile. Remove any you don't recognise.",
              ])),
        .init(id: "location-services", section: .security, title: "Location Services switch",
              reveals: "Whether Location Services is on at all.",
              why: "So apps know whether to ask.",
              persistence: .untilYouChangeIt, severity: .low, fix: .leaveIt("Nothing to change here. Per-app choices matter more; see the check-up.")),
    ]
}

// MARK: - Advanced

extension SignalCatalogue {
    static let advanced: [SignalDefinition] = [
        .init(id: "web-fingerprint", section: .web, title: "What websites inside apps see",
              reveals: "Many apps open web pages inside themselves. Those pages can read your languages, screen, time zone and graphics, and draw hidden images whose tiny differences tell devices apart.",
              why: "Web pages need some of this to display correctly.",
              persistence: .untilUpdate, severity: .low,
              fix: .guided("Open links in your browser, where tracking protection is stronger.", [
                  "Open Settings › Apps › Safari › Advanced.",
                  "Set Advanced Tracking and Fingerprinting Protection to All Browsing.",
              ])),
        .init(id: "reinstall-memory", section: .reinstall, title: "Recognised after you delete an app",
              reveals: "Apps can leave a note in the device's password store, which survives deleting the app. When you reinstall, the app finds its note and knows you're back, and how many times you've reinstalled.",
              why: "The password store keeps your sign-ins when you reinstall an app, and apps can store anything there.",
              persistence: .untilErase, severity: .high,
              fix: .onlyApple("Only erasing the whole device clears it. Apple could limit this.")),
    ]
}
