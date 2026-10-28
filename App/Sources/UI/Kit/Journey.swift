// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// The Score page, then the app's four steps in order. Each page ends by pointing to the next, so
/// nobody is left wondering where to go: see what's readable, what gives you away, what apps did,
/// then fix.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home, footprint, sensitive, tracker, checkup, settings

    /// The four checks, in order.
    static let checks: [AppTab] = [.footprint, .sensitive, .tracker, .checkup]
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Score"
        case .footprint: "Footprint"
        case .sensitive: "Sensitive apps"
        case .tracker: "Tracker"
        case .checkup: "Check-up"
        case .settings: "Settings"
        }
    }

    /// One word, for the navbar: six buttons fit side by side on the smallest iPhone (owner,
    /// 2026-10-28).
    var shortTitle: String { self == .sensitive ? "Sensitive" : title }

    var symbol: String {
        switch self {
        case .home: "gauge.with.needle"
        case .footprint: "pawprint"
        case .sensitive: "eye.slash"
        case .tracker: "antenna.radiowaves.left.and.right"
        case .checkup: "checklist"
        case .settings: "gearshape"
        }
    }

    /// Step number on the journey (Settings isn't one).
    var step: Int? {
        switch self {
        case .footprint: 1
        case .sensitive: 2
        case .tracker: 3
        case .checkup: 4
        case .home, .settings: nil
        }
    }

    var pitch: String {
        switch self {
        case .footprint: "See what any app can read about this device."
        case .sensitive: "See which of your apps any app can spot, and what that says about you."
        case .tracker: "See which apps used your data and who they talked to."
        case .checkup: "Go through Settings one area at a time and take access back."
        case .home, .settings: ""
        }
    }

    /// Accepts the old launch names used by screenshot scripts.
    init?(launchName: String) {
        switch launchName {
        case "home", "score": self = .home
        case "scan", "footprint": self = .footprint
        case "sensitive": self = .sensitive
        case "tracker", "report": self = .tracker
        case "checkup": self = .checkup
        case "settings": self = .settings
        default: return nil
        }
    }
}

/// "Next: …" at the end of a page: the one obvious way forward.
struct NextStepCard: View {
    let step: AppTab
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Brand.sand.opacity(0.14))
                    Text("\(step.step ?? 0)").font(.headline.monospacedDigit()).foregroundStyle(Brand.sand)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Brand.brandUppercased("Next: \(step.title)"))
                        .font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(Brand.sand)
                    Text(step.pitch)
                        .font(.subheadline).foregroundStyle(Brand.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.right.circle.fill").font(.title2).foregroundStyle(Brand.sand)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.sand.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Brand.sand.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("Next step: \(step.title). \(step.pitch)")
    }
}

/// Switching tabs: a quick cross-fade with a slight lift, or a plain fade with Reduce Motion.
struct TabSwitchTransition: ViewModifier {
    let tab: AppTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .id(tab)
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .opacity.combined(with: .offset(y: 12)), removal: .opacity))
    }
}

/// Lets any page move the person to another tab.
struct GoToTabKey: EnvironmentKey {
    static let defaultValue: (AppTab) -> Void = { _ in }
}

extension EnvironmentValues {
    var goToTab: (AppTab) -> Void {
        get { self[GoToTabKey.self] }
        set { self[GoToTabKey.self] = newValue }
    }
}

extension View {
    /// The tapped card is where the next page grows from (iOS's zoom transition, which the system
    /// turns into a fade under Reduce Motion). Elsewhere, the standard push.
    @ViewBuilder func zoomSource<ID: Hashable>(_ id: ID, in ns: Namespace.ID) -> some View {
        #if os(iOS)
        matchedTransitionSource(id: id, in: ns)
        #else
        self
        #endif
    }

    @ViewBuilder func zoomFrom<ID: Hashable>(_ id: ID, in ns: Namespace.ID) -> some View {
        #if os(iOS)
        navigationTransition(.zoom(sourceID: id, in: ns))
        #else
        self
        #endif
    }
}

// MARK: - The four checks, on the first page

extension OverallScore {
    /// Everything done so far: the Footprint scan (this one, or the last saved score), the saved
    /// sensitive-app and Tracker counts, the Check-up areas ticked and, on a Mac, the Tracker
    /// places looked through.
    @MainActor static func current(scanner: Scanner, history: HistoryStore, check: PrivacyCheck, checkUpStored: String, trackerStored: String = "") -> OverallScore {
        let ticked = Set(checkUpStored.split(separator: ",").map(String.init))
        let ids = Set(CheckUpGuide.steps.map(\.id))
        let reviewed = Set(trackerStored.split(separator: ",").map(String.init)).intersection(TrackerPlaces.ids).count
        return OverallScore(footprint: scanner.phase == .done ? scanner.score.value : history.latest?.score,
                            sensitiveFound: check.sensitiveFound,
                            trackerSharing: check.trackerSharing,
                            trackerReviewed: !TrackerPlaces.ids.isEmpty && reviewed == TrackerPlaces.ids.count,
                            checkUpDone: ticked.intersection(ids).count,
                            checkUpTotal: ids.count)
    }
}

/// The Mac's Tracker places, by id (MacTrackerView). Elsewhere the Tracker check reads a report.
enum TrackerPlaces {
    static let storageKey = "trackerChecked"
    #if os(macOS)
    static let ids: Set<String> = ["screen", "accessibility", "input", "files", "management", "login"]
    #else
    static let ids: Set<String> = []
    #endif
}

/// The four checks as rows: what each one does, whether it's done, and its part of the score.
/// Tapping one goes to that page, so the Score page is also the map of the whole app.
struct ChecksPanel: View {
    let overall: OverallScore
    @Environment(\.goToTab) private var goToTab
    @Environment(Scanner.self) private var scanner
    @Environment(PrivacyCheck.self) private var check
    @AppStorage("checkUpDone") private var checkUpStored = ""
    @AppStorage(TrackerPlaces.storageKey) private var trackerStored = ""

    var body: some View {
        Panel {
            ForEach(Array(AppTab.checks.enumerated()), id: \.element) { i, tab in
                Button {
                    Haptics.selection()
                    goToTab(tab)
                    // Footprint before its first scan: start it on the way there.
                    if tab == .footprint && scanner.phase == .idle && overall.parts[.footprint] == nil {
                        Task { await scanner.scan() }
                    }
                } label: {
                    row(number: i + 1, tab: tab)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func part(_ tab: AppTab) -> OverallScore.Part? {
        switch tab {
        case .footprint: .footprint
        case .sensitive: .sensitive
        case .tracker: .tracker
        case .checkup: .checkup
        case .home, .settings: nil
        }
    }

    private func status(_ tab: AppTab, value: Int?) -> String {
        switch tab {
        case .footprint:
            return value.map { FootprintScore.Level(value: $0).title } ?? "Not checked yet"
        case .sensitive:
            guard let n = check.sensitiveFound else { return "Not checked yet" }
            return n == 0 ? "No app can spot them" : (n == 1 ? "1 app can be spotted" : "\(n) apps can be spotted")
        case .tracker:
            #if os(macOS)
            let n = Set(trackerStored.split(separator: ",").map(String.init)).intersection(TrackerPlaces.ids).count
            return n == TrackerPlaces.ids.count ? "Every place checked" : (n == 0 ? "Not checked yet" : "\(n) of \(TrackerPlaces.ids.count) places checked")
            #else
            guard let n = check.trackerSharing else { return "Not checked yet" }
            return n == 0 ? "No app shared your data" : (n == 1 ? "1 app shared your data" : "\(n) apps shared your data")
            #endif
        case .checkup:
            let ticked = Set(checkUpStored.split(separator: ",").map(String.init)).intersection(CheckUpGuide.steps.map(\.id)).count
            return ticked == CheckUpGuide.steps.count ? "Every area checked" : (ticked == 0 ? "Not started" : "\(ticked) of \(CheckUpGuide.steps.count) areas checked")
        case .home, .settings:
            return ""
        }
    }

    private func row(number: Int, tab: AppTab) -> some View {
        let value = part(tab).flatMap { overall.parts[$0] }
        let done = value != nil
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(done ? Tone.fix.tint.opacity(0.16) : Brand.sand.opacity(0.12))
                if done {
                    Image(systemName: "checkmark").font(.subheadline.weight(.bold)).foregroundStyle(Tone.fix.tint)
                } else {
                    Text("\(number)").font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(Brand.sand)
                }
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title).font(.body.weight(.semibold)).foregroundStyle(Brand.ink)
                Text(tab.pitch).font(.footnote).foregroundStyle(Brand.textSubtle)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Text(status(tab, value: value))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(done ? Tone.fix.tint : Brand.sand)
            }
            Spacer(minLength: 8)
            if let value {
                Text("\(value)").font(.title3.weight(.semibold).monospacedDigit()).foregroundStyle(Brand.ink)
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.textSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) { Rectangle().fill(Brand.rule).frame(height: 0.5).padding(.leading, 62) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(tab.title). \(status(tab, value: value))\(value.map { ". Score \($0)" } ?? "")")
    }
}

// MARK: - List and detail side by side

/// A page with a list (clues, Check-up areas) whose rows open a detail. On a regular-width screen
/// (an open iPhone Duo, iPad) the detail sits beside the list, as Mail does; folded or on a
/// regular iPhone it collapses to one pane and rows push as before. The system sizes the columns
/// and evens them out around the fold. The Mac's pages already sit inside its own sidebar.
struct ListDetailStack<Content: View, Placeholder: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var placeholder: Placeholder
    #if os(iOS)
    @State private var column: NavigationSplitViewColumn = .sidebar
    #endif

    var body: some View {
        #if os(iOS)
        NavigationSplitView(preferredCompactColumn: $column) {
            content
                .navigationSplitViewColumnWidth(min: 340, ideal: 420, max: 520)
        } detail: {
            NavigationStack { placeholder }
        }
        .navigationSplitViewStyle(.balanced)
        #else
        NavigationStack { content }
        #endif
    }
}

/// What the detail side shows before anything is picked.
struct DetailPlaceholder: View {
    let line: String

    var body: some View {
        VStack(spacing: 16) {
            LivingMascot(mood: .thinking, size: 120)
            Text(line)
                .font(.body)
                .foregroundStyle(Brand.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandBackground())
    }
}
