// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)

#if DEBUG
import SwiftUI
import UIKit

/// Debug-only test bench for "take me there" fix buttons. It tries each candidate link to a
/// Settings screen and records whether iOS accepted it. A link counts as working only if it also
/// *lands on the right screen*, which someone has to check by eye on a real device. Results go in
/// docs/SETTINGS-LINKS.md.
///
/// Only the first two links are official API. Everything else is unofficial and may break in any
/// iOS update or draw an App Review objection; see docs/SETTINGS-LINKS.md before shipping any.
struct SettingsLinkLab: View {
    struct Candidate: Identifiable {
        let id: String
        let label: String
        var url: URL? { URL(string: id) }
    }

    static let candidates: [Candidate] = [
        .init(id: UIApplication.openSettingsURLString, label: "Official: this app's Settings page"),
        .init(id: "App-prefs:", label: "Settings root"),
        .init(id: "App-prefs:Privacy", label: "Privacy & Security"),
        .init(id: "App-prefs:Privacy&path=LOCATION", label: "Location Services"),
        .init(id: "App-prefs:Privacy&path=HEALTH", label: "Health"),
        .init(id: "App-prefs:Privacy&path=PHOTOS", label: "Photos"),
        .init(id: "App-prefs:Privacy&path=CONTACTS", label: "Contacts"),
        .init(id: "App-prefs:Privacy&path=CALENDARS", label: "Calendars"),
        .init(id: "App-prefs:Privacy&path=BLUETOOTH", label: "Bluetooth permission"),
        .init(id: "App-prefs:Privacy&path=USER_TRACKING", label: "Tracking"),
        .init(id: "App-prefs:Privacy&path=PROBLEM_REPORTING", label: "Analytics & Improvements"),
        .init(id: "App-prefs:Privacy&path=LOCKDOWN_MODE", label: "Lockdown Mode"),
        .init(id: "App-prefs:Bluetooth", label: "Bluetooth (devices, AirPods name)"),
        .init(id: "App-prefs:General&path=About", label: "General › About (device name)"),
        .init(id: "App-prefs:General&path=Keyboard", label: "General › Keyboard"),
        .init(id: "App-prefs:MOBILE_DATA_SETTINGS_ID", label: "Mobile Data (per-app switch)"),
        .init(id: "App-prefs:SAFARI", label: "Safari"),
        .init(id: "App-prefs:CASTLE", label: "Apple Account › iCloud"),
        .init(id: "prefs:root=Privacy", label: "Legacy prefs: scheme"),
    ]

    @State private var results: [String: Bool] = [:]

    var body: some View {
        List(Self.candidates) { candidate in
            Button {
                guard let url = candidate.url else { results[candidate.id] = false; return }
                UIApplication.shared.open(url) { accepted in
                    results[candidate.id] = accepted
                }
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(candidate.label)
                        Text(candidate.id).font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    switch results[candidate.id] {
                    case true?: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    case false?: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    case nil: EmptyView()
                    }
                }
            }
        }
        .navigationTitle("Settings link lab")
    }
}
#endif
#endif
