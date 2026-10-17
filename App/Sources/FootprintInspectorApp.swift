// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@main
struct FootprintInspectorApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Phase 1 placeholder. The real home screen arrives in Phase 2.
struct RootView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Groundwork build. The scanner arrives in Phase 2.")
                        .foregroundStyle(.secondary)
                }
                #if DEBUG
                Section("Developer") {
                    NavigationLink("Settings link lab") { SettingsLinkLab() }
                }
                #endif
            }
            .navigationTitle("Footprint Inspector")
        }
    }
}
