// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@main
struct FootprintInspectorApp: App {
    @State private var history: HistoryStore
    @State private var scanner: Scanner
    @State private var check = PrivacyCheck()

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
                .environment(check)
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
                .environment(check)
                .tint(Brand.accent)
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(minWidth: 820, minHeight: 600)
                #endif
        }
    }
}

struct RootView: View {
    /// Screenshot runs can open on a given tab with `-startTab footprint|sensitive|tracker|checkup|settings`.
    @State private var tab: AppTab = LaunchOptions.value(after: "-startTab").flatMap(AppTab.init(launchName:)) ?? .footprint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PrivacyCheck.self) private var check
    #if os(macOS)
    @Environment(\.openSettings) private var openSettings
    #endif

    private func go(_ t: AppTab) {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.32)) { tab = t }
    }

    var body: some View {
        #if os(macOS)
        // A sidebar on the Mac; Settings lives in its own window (⌘,).
        NavigationSplitView {
            List(selection: Binding<AppTab?>(get: { tab }, set: { if let t = $0 { go(t) } })) {
                ForEach([AppTab.footprint, .sensitive, .tracker, .checkup]) { t in
                    Label(t.title, systemImage: t.symbol).tag(t)
                }
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
            Group {
                switch tab {
                case .sensitive: SensitiveView()
                case .tracker: MacTrackerView()
                case .checkup: CheckUpView()
                default: ScanView()
                }
            }
            .modifier(TabSwitchTransition(tab: tab))
        }
        .environment(\.goToTab, go)
        .onChange(of: scenePhase) { _, phase in if phase == .background { check.clearSessionResults() } }
        .task { if CommandLine.arguments.contains("-openSettings") { openSettings() } }
        #else
        TabView(selection: Binding(get: { tab }, set: { t in go(t); Haptics.selection() })) {
            ForEach(AppTab.allCases) { t in
                Tab(t.title, systemImage: t.symbol, value: t) { page(t) }
            }
        }
        // Named pages in a sidebar on wide screens (an open iPhone Duo, iPad); the system's own
        // tab bar or side strip everywhere else.
        .tabViewStyle(.sidebarAdaptable)
        .environment(\.goToTab, go)
        .onChange(of: scenePhase) { _, phase in if phase == .background { check.clearSessionResults() } }
        #endif
    }

    #if os(iOS)
    @ViewBuilder private func page(_ t: AppTab) -> some View {
        switch t {
        case .footprint: ScanView()
        case .sensitive: SensitiveView()
        case .tracker: PrivacyReportView(onNext: { go(.checkup) })
        case .checkup: CheckUpView()
        case .settings: SettingsView()
        }
    }
    #endif
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
