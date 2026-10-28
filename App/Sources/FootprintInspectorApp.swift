// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@main
struct FootprintInspectorApp: App {
    @State private var history: HistoryStore
    @State private var scanner: Scanner
    @State private var check = PrivacyCheck(defaults: LaunchOptions.has("-sampleData") ? nil : .standard)

    init() {
        // Store screenshots and UI tests start clean every time, with nothing from earlier runs.
        let history = LaunchOptions.has("-sampleData")
            ? HistoryStore(directory: FileManager.default.temporaryDirectory.appending(path: "sample-\(UUID().uuidString)"))
            : HistoryStore()
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
    /// Screenshot runs can open on a given tab with `-startTab home|footprint|sensitive|tracker|checkup|settings`.
    /// With `-autoScan` and no start tab, runs open on Footprint, where the scan shows.
    @State private var tab: AppTab = LaunchOptions.value(after: "-startTab").flatMap(AppTab.init(launchName:)) ?? (LaunchOptions.autoScan ? .footprint : .home)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PrivacyCheck.self) private var check
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
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
                ForEach([AppTab.home] + AppTab.checks) { t in
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
                case .footprint: ScanView()
                case .sensitive: SensitiveView()
                case .tracker: MacTrackerView()
                case .checkup: CheckUpView()
                default: ScoreHomeView()
                }
            }
            .modifier(TabSwitchTransition(tab: tab))
        }
        .environment(\.goToTab, go)
        .modifier(KeepScoreFresh())
        // Store screenshots: a Sensitive check with nothing found, as on iOS.
        .task { if LaunchOptions.has("-sampleData") { check.recordSensitive(found: 0) } }
        .task { if LaunchOptions.has("-openSettings") { openSettings() } }
        #else
        Group {
            if horizontalSizeClass == .regular || verticalSizeClass == .compact {
                // Wide or sideways: named on the left, or an icon rail on the right; Settings at the bottom.
                SideRail(tab: Binding(get: { tab }, set: { go($0) }), tabs: AppTab.allCases) { page($0) }
            } else {
                // Upright on a phone: the tab bar, with Settings on the Score page.
                TabView(selection: Binding(get: { tab == .settings ? .home : tab }, set: { t in go(t); Haptics.selection() })) {
                    ForEach([AppTab.home] + AppTab.checks) { t in
                        Tab(t.title, systemImage: t.symbol, value: t) { page(t, settingsOnScore: true) }
                    }
                }
            }
        }
        .environment(\.goToTab, go)
        .modifier(KeepScoreFresh())
        // Store screenshots: the sample Tracker report and a Sensitive check with nothing found, so
        // every screen can be captured from launch switches alone (the iPhone Duo can't be tapped
        // by tests in every pose).
        .task { if LaunchOptions.has("-sampleData") { check.recordTracker(sharing: PrivacyReport.sample.sharing.count); check.recordSensitive(found: 0) } }
        #endif
    }

    #if os(iOS)
    @ViewBuilder private func page(_ t: AppTab, settingsOnScore: Bool = false) -> some View {
        switch t {
        case .home: ScoreHomeView(showsSettingsButton: settingsOnScore)
        case .footprint: ScanView()
        case .sensitive: SensitiveView()
        case .tracker: PrivacyReportView(onNext: { go(.checkup) })
        case .checkup: CheckUpView()
        case .settings: SettingsView()
        }
    }
    #endif
}

/// Keeps the Footprint part of the score current: on launch, and each time the app comes back to
/// the screen (after changing a setting, say), it re-reads quietly if a scan was done before.
private struct KeepScoreFresh: ViewModifier {
    @Environment(Scanner.self) private var scanner
    @Environment(HistoryStore.self) private var history
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task { if history.latest != nil && !LaunchOptions.autoScan { await scanner.scan(quietly: true) } }
            .onChange(of: scenePhase) { old, phase in
                if phase == .active && old != .active && scanner.phase == .done { Task { await scanner.scan(quietly: true) } }
            }
    }
}

/// Launch switches used only to take store screenshots and run UI tests without clicking through
/// by hand. They work in Debug builds only: in a store build any program that can launch the app
/// (on a Mac, any local process) could otherwise make it show made-up, reassuring results.
enum LaunchOptions {
    #if DEBUG
    private static let args = CommandLine.arguments
    #else
    private static let args: [String] = []
    #endif

    static func has(_ flag: String) -> Bool { args.contains(flag) }

    static func value(after flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    static var autoScan: Bool { has("-autoScan") }
}
