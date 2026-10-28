// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)
import SwiftUI

/// The pages down the side, on wide screens (an open iPhone Duo, iPad) and whenever the device is
/// sideways (owner, 2026-10-28): a named sidebar on the left, as on the Mac, when there's room;
/// otherwise an icon rail on the right, as the system does on an iPhone Duo.
struct SideRail<PageContent: View>: View {
    @Binding var tab: AppTab
    let tabs: [AppTab]
    @ViewBuilder let page: (AppTab) -> PageContent

    var body: some View {
        GeometryReader { geo in
            let named = geo.size.width >= 820
            HStack(spacing: 0) {
                if named { sidebar(named: true); divider }
                // Only the chosen page exists, so VoiceOver never reaches a hidden one.
                page(tab)
                    .id(tab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if !named { divider; sidebar(named: false) }
            }
        }
    }

    private var divider: some View { Rectangle().fill(Brand.rule).frame(width: 0.5).ignoresSafeArea() }

    private func sidebar(named: Bool) -> some View {
        rail(named: named)
            .frame(width: named ? 230 : 84)
            .background(Brand.surface.ignoresSafeArea())
    }

    private func rail(named: Bool) -> some View {
        // Fits a phone held sideways (about 400 points tall); scrolls rather than clip if not.
        ScrollView(.vertical) {
            railItems(named: named)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func railItems(named: Bool) -> some View {
        VStack(alignment: named ? .leading : .center, spacing: named ? 4 : 2) {
            ForEach(tabs.filter { $0 != .settings }) { t in item(t, named: named) }
            Spacer(minLength: named ? 24 : 6)
            if named {
                Image("MascotCutout").resizable().scaledToFit().frame(height: 56)
                    .frame(maxWidth: .infinity).accessibilityHidden(true)
            }
            if tabs.contains(.settings) { item(.settings, named: named) }
        }
        .padding(.horizontal, named ? 12 : 6)
        .padding(.vertical, named ? 16 : 6)
    }

    private func item(_ t: AppTab, named: Bool) -> some View {
        let selected = t == tab
        return Button {
            Haptics.selection()
            tab = t
        } label: {
            Group {
                if named {
                    Label(t.title, systemImage: t.symbol)
                        .font(.body.weight(selected ? .semibold : .regular))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: t.symbol).font(.body)
                        Text(t.title).font(.caption2.weight(.medium)).lineLimit(2).multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
            }
            .foregroundStyle(selected ? Brand.sand : Brand.textMuted)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(selected ? Brand.surfaceRaised : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
#endif
