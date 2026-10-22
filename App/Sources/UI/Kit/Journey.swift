// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// The app's four steps, in order. Each page ends by pointing to the next, so nobody is left
/// wondering where to go: see what's readable, what gives you away, what apps did, then fix.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case footprint, sensitive, tracker, checkup, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .footprint: "Footprint"
        case .sensitive: "Sensitive apps"
        case .tracker: "Tracker"
        case .checkup: "Check-up"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
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
        case .settings: nil
        }
    }

    var pitch: String {
        switch self {
        case .footprint: "See what any app can read about this device."
        case .sensitive: "See which of your apps any app can spot, and what that says about you."
        case .tracker: "See which apps used your data and who they talked to."
        case .checkup: "Go through Settings one area at a time and take access back."
        case .settings: ""
        }
    }

    /// Accepts the old launch names used by screenshot scripts.
    init?(launchName: String) {
        switch launchName {
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
