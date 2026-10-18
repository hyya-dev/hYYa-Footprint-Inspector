// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

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
}

enum CheckUpGuide {
    static let steps: [CheckUpStep] = [
        .init(id: "safety-check", title: "Start with Safety Check", symbol: "checkmark.shield",
              why: "Apple's own review of who and what can reach your information. It covers people you share with and app permissions in one place.",
              path: "Settings › Privacy & Security › Safety Check",
              actions: ["Tap Manage Sharing & Access.", "Go through each screen and remove anything you don't recognise or no longer need."]),
        .init(id: "health", title: "Health", symbol: "heart.text.square",
              why: "Health data is the most personal information on your device: sleep, heart, cycles, medicines.",
              path: "Settings › Health › Data Access & Devices",
              actions: ["Open each app in the list.", "Turn off any data type the app doesn't truly need.", "Remove apps you no longer use."]),
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
              why: "Calendars show your routine and often your employer's email domain.",
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
}
