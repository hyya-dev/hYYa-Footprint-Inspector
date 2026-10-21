// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@main
struct FootprintInspectorApp: App {
    @State private var history: HistoryStore
    @State private var scanner: Scanner

    init() {
        let history = HistoryStore()
        _history = State(initialValue: history)
        _scanner = State(initialValue: Scanner(history: history))
    }

    var body: some Scene {
        #if os(macOS)
        mainWindow
            .defaultSize(width: 1280, height: 800)
            .windowToolbarStyle(.unifiedCompact)

        // The Mac's standard Settings window (⌘,), with the same content as the iOS Settings tab.
        Settings {
            SettingsView()
                .environment(scanner)
                .environment(history)
                .tint(Brand.accent)
                .preferredColorScheme(.dark)
                .frame(width: 560, height: 680)
        }
        #else
        mainWindow
        #endif
    }

    private var mainWindow: some Scene {
        WindowGroup {
            RootView()
                .environment(scanner)
                .environment(history)
                .tint(Brand.accent)
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(minWidth: 820, minHeight: 600)
                #endif
        }
    }
}

struct RootView: View {
    /// Screenshot runs can open on a given tab with `-startTab sensitive|checkup`.
    @State private var tab: String? = LaunchOptions.value(after: "-startTab") ?? "scan"
    #if os(macOS)
    @Environment(\.openSettings) private var openSettings
    #endif

    var body: some View {
        #if os(macOS)
        // A sidebar on the Mac; Settings lives in its own window (⌘,).
        NavigationSplitView {
            List(selection: $tab) {
                Label("Scan", systemImage: "magnifyingglass").tag("scan")
                Label("Sensitive apps", systemImage: "eye.slash").tag("sensitive")
                Label("Check-up", systemImage: "checklist").tag("checkup")
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 6) {
                    Image("MascotCutout").resizable().scaledToFit().frame(height: 64).accessibilityHidden(true)
                    Text(Brand.brandUppercased("hYYa Footprint Inspector"))
                        .font(.caption2.weight(.semibold)).tracking(1.2)
                        .foregroundStyle(Brand.textSubtle)
                        .multilineTextAlignment(.center)
                    SwiftUI.SettingsLink { Label("Settings", systemImage: "gearshape").labelStyle(.titleAndIcon) }
                        .buttonStyle(.borderless)
                        .foregroundStyle(Brand.sand)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        } detail: {
            switch tab {
            case "sensitive": SensitiveView()
            case "checkup": CheckUpView()
            default: ScanView()
            }
        }
        .task { if CommandLine.arguments.contains("-openSettings") { openSettings() } }
        #else
        TabView {
            Tab("Scan", systemImage: "magnifyingglass") { ScanView() }
            Tab("Sensitive apps", systemImage: "eye.slash") { SensitiveView() }
            Tab("Check-up", systemImage: "checklist") { CheckUpView() }
            Tab("Settings", systemImage: "gearshape") { SettingsView() }
        }
        #endif
    }
}

/// Launch switches used only to take store screenshots without clicking through by hand.
enum LaunchOptions {
    static func value(after flag: String) -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    static var autoScan: Bool { CommandLine.arguments.contains("-autoScan") }
}
