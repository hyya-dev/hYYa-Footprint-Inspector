// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(macOS)
import SwiftUI

/// The Tracker step on a Mac. A Mac keeps no App Privacy Report, and the sandbox hides who holds
/// which access, so this page lists the places that do show it, each one click away.
struct MacTrackerView: View {
    @Environment(\.goToTab) private var goToTab
    /// Places looked through, kept on this Mac like the Check-up's areas. Once all are ticked,
    /// Tracker counts as 100 in the privacy score.
    @AppStorage(TrackerPlaces.storageKey) private var stored = ""
    private var checked: Set<String> { Set(stored.split(separator: ",").map(String.init)).intersection(TrackerPlaces.ids) }

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
                let done = checked.count, total = places.count
                HeroCard(eyebrow: "Tracker", title: done == total ? "All checked!" : "Who can watch you?",
                         subtitle: "A Mac doesn't keep a record of what apps did, and it doesn't tell one app which others hold powerful access. These are the places that show it. Open each, remove anything you don't recognise, then tick it.",
                         mood: done == total ? .happy : .thinking, mascotSize: 96) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(done == total ? "Tracker counts as 100 in your privacy score." : "\(done) of \(total) checked. Tick all \(total) and Tracker counts in your privacy score.")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(done == total ? Tone.fix.tint : Brand.sand)
                        ProgressView(value: Double(done), total: Double(total)).tint(Tone.fix.tint)
                            .animation(.spring, value: done)
                    }
                    .padding(.top, 6)
                }
                ForEach(places) { place in
                    let isDone = checked.contains(place.id)
                    ToneCard(tone: isDone ? .fix : place.tone, title: place.title, symbol: isDone ? "checkmark" : place.symbol) {
                        Text(place.why).font(.body).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 12) {
                            Button("Open in System Settings") { SettingsLink.open(pane: place.pane); Haptics.selection() }
                                .buttonStyle(GhostButtonStyle())
                            Button(isDone ? "Checked ✓" : "I've checked this") { toggle(place.id) }
                                .buttonStyle(PrimaryCTAButtonStyle(fill: isDone ? Brand.green : Brand.cta,
                                                                   depthColor: isDone ? Color(hex: 0x0E8A56) : Brand.ctaDepth))
                        }
                    }
                }
                if done > 0 { NextStepCard(step: .checkup) { goToTab(.checkup) } }
            }
            .navigationTitle("Tracker")
            .sensoryFeedback(.success, trigger: checked.count == places.count)
        }
    }

    private func toggle(_ id: String) {
        var set = checked
        if set.contains(id) { set.remove(id) } else { set.insert(id); Haptics.success() }
        stored = set.sorted().joined(separator: ",")
    }
}
#endif
