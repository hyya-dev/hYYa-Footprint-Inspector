// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@main
struct FootprintInspectorApp: App {
    @State private var history: HistoryStore
    @State private var scanner: Scanner
    @AppStorage("theme") private var theme: AppTheme = .auto

    init() {
        let history = HistoryStore()
        _history = State(initialValue: history)
        _scanner = State(initialValue: Scanner(history: history))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(scanner)
                .environment(history)
                .tint(Brand.accent)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Scan", systemImage: "magnifyingglass") { ScanView() }
            Tab("Sensitive apps", systemImage: "eye.slash") { SensitiveView() }
            Tab("Check-up", systemImage: "checklist") { CheckUpView() }
            Tab("Settings", systemImage: "gearshape") { SettingsView() }
            #if DEBUG
            Tab("Lab", systemImage: "hammer") { NavigationStack { SettingsLinkLab() } }
            #endif
        }
    }
}
