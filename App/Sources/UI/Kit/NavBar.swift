// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)
import SwiftUI

/// The app's own navbar, the same on every iPhone and iPad (owner, 2026-10-28): along the bottom
/// when the screen is upright, down the left edge when it's sideways. All six pages, Settings
/// included, each with an icon and a one-word name. It's drawn here rather than by the system,
/// whose tab bar moves to the right edge on an iPhone Duo and has room for five.
struct NavBarRoot<PageContent: View>: View {
    @Binding var tab: AppTab
    @ViewBuilder let page: (AppTab) -> PageContent

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                HStack(spacing: 0) {
                    bar(vertical: true)
                        .frame(width: 84)
                        .background(Brand.surface.ignoresSafeArea())
                    Rectangle().fill(Brand.rule).frame(width: 0.5).ignoresSafeArea()
                    current
                }
            } else {
                VStack(spacing: 0) {
                    current
                    Rectangle().fill(Brand.rule).frame(height: 0.5)
                    bar(vertical: false)
                        // Runs under the home indicator and, on an iPhone Duo, under the side status strip.
                        .background(Brand.surface.ignoresSafeArea(edges: [.bottom, .horizontal]))
                }
            }
        }
    }

    /// Only the chosen page exists, so VoiceOver never reaches a hidden one.
    private var current: some View {
        page(tab)
            .id(tab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bar(vertical: Bool) -> some View {
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 2)) : AnyLayout(HStackLayout(spacing: 0))
        return layout {
            ForEach(AppTab.allCases) { t in item(t, vertical: vertical) }
        }
        .padding(vertical ? .vertical : .top, vertical ? 6 : 4)
        .fixedSize(horizontal: false, vertical: !vertical)
        .padding(.horizontal, vertical ? 4 : 2)
        .frame(maxHeight: vertical ? .infinity : nil)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("navbar")
    }

    private func item(_ t: AppTab, vertical: Bool) -> some View {
        let selected = t == tab
        return Button {
            Haptics.selection()
            tab = t
        } label: {
            VStack(spacing: 3) {
                Image(systemName: t.symbol).font(.system(size: 19, weight: selected ? .semibold : .regular))
                    .frame(height: 24)
                Text(t.shortTitle)
                    .font(.system(size: 10.5, weight: selected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(selected ? Brand.sand : Brand.textMuted)
            // Sideways the six share the rail's height; upright the bar is only as tall as a button.
            .frame(maxWidth: .infinity, maxHeight: vertical ? .infinity : nil)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(selected ? Brand.surfaceRaised : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The names stay one size so all six always fit; VoiceOver reads the full name.
        .dynamicTypeSize(...DynamicTypeSize.large)
        .accessibilityLabel(t.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
#endif
