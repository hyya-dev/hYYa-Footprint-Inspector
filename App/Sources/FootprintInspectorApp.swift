// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@main
struct FootprintInspectorApp: App {
    @State private var scanner = Scanner()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(scanner)
                .tint(Brand.blue)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Scan", systemImage: "magnifyingglass") { ScanView() }
            Tab("Sensitive apps", systemImage: "eye.slash") { SensitiveView() }
            Tab("Check-up", systemImage: "checklist") { CheckUpView() }
            #if DEBUG
            Tab("Lab", systemImage: "hammer") { NavigationStack { SettingsLinkLab() } }
            #endif
        }
    }
}
