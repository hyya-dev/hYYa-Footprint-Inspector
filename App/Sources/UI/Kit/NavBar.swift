// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)
import SwiftUI

/// The app's own navbar: all six pages, Settings included, each with an icon and a one-word name
/// (owner, 2026-10-28). It goes where the iPhone Duo puts its own:
/// - beside the system's status strip, when the system keeps a strip down the right edge only
///   (a Duo folded upright, or open sideways), in the strip's column below the clock;
/// - down the left edge when sideways otherwise, flush with the edge and below a camera there
///   (a Duo folded sideways);
/// - along the bottom when upright otherwise (a Duo open upright, every other iPhone, iPad).
/// Drawn here rather than by the system tab bar, which has room for five.
struct NavBarRoot<PageContent: View>: View {
    @Binding var tab: AppTab
    @ViewBuilder let page: (AppTab) -> PageContent

    enum Place: Equatable { case bottom, left, leftBelowCamera, right }

    static func place(size: CGSize, insets: EdgeInsets) -> Place {
        if insets.trailing > 0 && insets.leading == 0 { return .right }
        if size.width > size.height { return insets.leading > 0 && insets.trailing == 0 ? .leftBelowCamera : .left }
        return .bottom
    }

    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets
            switch Self.place(size: geo.size, insets: insets) {
            case .bottom:
                VStack(spacing: 0) {
                    current
                    Rectangle().fill(Brand.rule).frame(height: 0.5)
                    bar(vertical: false)
                        // Runs under the home indicator.
                        .background(Brand.surface.ignoresSafeArea(edges: [.bottom, .horizontal]))
                }
            case .left:
                HStack(spacing: 0) {
                    rail(width: 84, bottomAligned: false)
                        .background(Brand.surface.ignoresSafeArea())
                    divider
                    current
                }
            case .leftBelowCamera:
                // Flush with the left edge, the buttons gathered at the bottom, clear of the camera.
                HStack(spacing: 0) {
                    rail(width: max(insets.leading, 76), bottomAligned: true)
                        .padding(.leading, -insets.leading)
                        .background(Brand.surface.ignoresSafeArea())
                    divider
                    current
                }
            case .right:
                // In the status strip's column, the buttons gathered at the bottom, below the clock.
                HStack(spacing: 0) {
                    current
                    divider
                    rail(width: max(insets.trailing, 76), bottomAligned: true)
                        .padding(.trailing, -insets.trailing)
                        .background(Brand.surface.ignoresSafeArea())
                }
            }
        }
    }

    private var divider: some View { Rectangle().fill(Brand.rule).frame(width: 0.5).ignoresSafeArea() }

    /// Only the chosen page exists, so VoiceOver never reaches a hidden one.
    private var current: some View {
        page(tab)
            .id(tab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bar(vertical: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { t in item(t, stretch: false) }
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("navbar")
    }

    /// Down a side: the six share the height, or sit together at the bottom where the top of
    /// that edge belongs to the clock or a camera.
    private func rail(width: CGFloat, bottomAligned: Bool) -> some View {
        VStack(spacing: 2) {
            if bottomAligned { Spacer(minLength: 0) }
            ForEach(AppTab.allCases) { t in
                item(t, stretch: !bottomAligned)
                    .frame(height: bottomAligned ? 56 : nil)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("navbar")
    }

    private func item(_ t: AppTab, stretch: Bool) -> some View {
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
            .frame(maxWidth: .infinity, maxHeight: stretch ? .infinity : nil)
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
