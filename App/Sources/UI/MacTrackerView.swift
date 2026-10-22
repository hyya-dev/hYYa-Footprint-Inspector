// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(macOS)
import SwiftUI

/// The Tracker step on a Mac. A Mac keeps no App Privacy Report, and the sandbox hides who holds
/// which access, so this page lists the places that do show it, each one click away.
struct MacTrackerView: View {
    @Environment(\.goToTab) private var goToTab
    @State private var openedOne = false

    private struct Place: Identifiable {
        let id: String
        let title: String
        let symbol: String
        let why: String
        let pane: String
        let tone: Tone
    }

    private let places: [Place] = [
        .init(id: "screen", title: "Screen and audio recording", symbol: "rectangle.dashed.badge.record",
              why: "Apps here can see everything on your screen, including messages and passwords as you type.",
              pane: MacSignalCatalogue.Pane.privacy("Privacy_ScreenCapture"), tone: .alert),
        .init(id: "accessibility", title: "Accessibility", symbol: "accessibility",
              why: "Apps here can read what's on screen and control your Mac. Keep only tools you rely on.",
              pane: MacSignalCatalogue.Pane.privacy("Privacy_Accessibility"), tone: .alert),
        .init(id: "input", title: "Input monitoring", symbol: "keyboard",
              why: "Apps here can see every key you press, in every app.",
              pane: MacSignalCatalogue.Pane.privacy("Privacy_ListenEvent"), tone: .alert),
        .init(id: "files", title: "Full Disk Access", symbol: "internaldrive",
              why: "Apps here can read almost every file, including mail and messages.",
              pane: MacSignalCatalogue.Pane.privacy("Privacy_AllFiles"), tone: .context),
        .init(id: "management", title: "Device Management", symbol: "gearshape.2",
              why: "A profile here can let an organisation manage this Mac or route its traffic.",
              pane: "com.apple.Profiles-Settings.extension", tone: .context),
        .init(id: "login", title: "Login items", symbol: "power",
              why: "These start every time you log in and can run in the background all day.",
              pane: "com.apple.LoginItems-Settings.extension", tone: .context),
    ]

    var body: some View {
        NavigationStack {
            Page {
                HeroCard(eyebrow: "Tracker", title: "Who can watch you?",
                         subtitle: "A Mac doesn't keep a record of what apps did, and it doesn't tell one app which others hold powerful access. These are the places that show it. Open each and remove anything you don't recognise.",
                         mood: .thinking, mascotSize: 96)
                ForEach(places) { place in
                    ToneCard(tone: place.tone, title: place.title, symbol: place.symbol) {
                        Text(place.why).font(.body).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                        Button("Open in System Settings") { SettingsLink.open(pane: place.pane); Haptics.selection(); withAnimation(.smooth) { openedOne = true } }
                            .buttonStyle(GhostButtonStyle())
                    }
                }
                if openedOne { NextStepCard(step: .checkup) { goToTab(.checkup) } }
            }
            .navigationTitle("Tracker")
        }
    }
}
#endif
