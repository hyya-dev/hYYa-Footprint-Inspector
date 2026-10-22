// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// What a card is for. Each role has one colour, used for the card's edge, a faint wash, its icon
/// and its badge; body text stays white or grey so it always reads. Every tint is at least 6:1
/// against the panel (WCAG AA for body text, AAA for most). Dark only, like the rest of Quiet
/// Noir; the pairs below keep a light mode cheap if it's ever wanted.
enum Tone: Sendable {
    /// Worth a look, concerning notes.
    case alert
    /// What a clue tells an app; the mascot's notes. The mascot's own blue.
    case explain
    /// Why the system allows it, details, background.
    case context
    /// How to fix it, things done.
    case fix
    /// Only Apple, Google or the maker can fix it: nothing for the person to do.
    case limit

    var tint: Color {
        switch self {
        case .alert: Brand.concern                      // #EC7F6A, 6.9:1
        case .explain: Color(hex: 0x7FB2E5)             // 8.6:1
        case .context: Brand.sand                       // #D2AE88, 9.4:1
        case .fix: Brand.green                          // #7CD9A8, 11:1
        case .limit: Color(hex: 0xA7AFBF)               // 8.3:1
        }
    }

    /// The faint wash behind the card's top edge.
    var wash: Color { tint.opacity(0.07) }
    /// The badge fill behind tinted text.
    var badge: Color { tint.opacity(0.14) }
}

/// A card with a role: a tinted icon and title, optional trailing badge, then free content.
/// One level only: never put a ToneCard inside another card.
struct ToneCard<Content: View, Trailing: View>: View {
    let tone: Tone
    var title: String? = nil
    var symbol: String? = nil
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(alignment: .center, spacing: 10) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tone.tint)
                            .frame(width: 30, height: 30)
                            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tone.badge))
                    }
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Brand.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    trailing
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            shape.fill(Brand.surface)
                .overlay(shape.fill(LinearGradient(colors: [tone.wash, .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.6))))
        )
        .overlay(shape.strokeBorder(LinearGradient(colors: [tone.tint.opacity(0.55), tone.tint.opacity(0.15)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
        // Depth without glow: a fine light catch on the top edge and a soft shadow underneath.
        .overlay(alignment: .top) {
            shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.10), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.08)), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.55), radius: 16, x: 0, y: 10)
        .scrollIn3D()
    }
}

extension ToneCard where Trailing == EmptyView {
    init(tone: Tone, title: String? = nil, symbol: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(tone: tone, title: title, symbol: symbol, trailing: { EmptyView() }, content: content)
    }
}

/// A tinted label: role colour on a faint fill of the same colour.
struct ToneBadge: View {
    let text: String
    var symbol: String? = nil
    let tone: Tone

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.caption.weight(.semibold)) }
            Text(text)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tone.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(tone.badge))
    }
}

/// Lays badges out left to right and wraps to a new line when they don't fit, so a long label
/// is never cut off on a small screen or with large text.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0, widest: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if x > 0 && x + size.width > width { x = 0; y += line + spacing; line = 0 }
            x += size.width + spacing
            line = max(line, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, width), height: y + line)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, line: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX && x + size.width > bounds.maxX { x = bounds.minX; y += line + spacing; line = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
            x += size.width + spacing
            line = max(line, size.height)
        }
    }
}
