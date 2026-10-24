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

/// A ring chart summing up a page at a glance, with a legend. Coral is worth a look, amber worth
/// knowing, green fine: the same meaning on every page.
struct SummaryRing: View {
    struct Slice: Identifiable { let label: String; let count: Int; let color: Color; var id: String { label } }
    let slices: [Slice]
    var centre: String? = nil
    var caption: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var shown = false

    private var total: Int { max(1, slices.reduce(0) { $0 + $1.count }) }

    var body: some View {
        // Ring beside its legend; ring above it at the largest text sizes, where the legend's
        // words no longer fit beside the ring.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14)) : AnyLayout(HStackLayout(spacing: 18))
        layout {
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 14)
                ForEach(Array(slices.enumerated()), id: \.offset) { i, s in
                    let start = Double(slices.prefix(i).reduce(0) { $0 + $1.count }) / Double(total)
                    let end = start + Double(s.count) / Double(total)
                    Circle()
                        .trim(from: start, to: shown ? max(start, end - (s.count > 0 ? 0.004 : 0)) : start)
                        .stroke(s.color, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 0) {
                    Text(centre ?? "\(slices.reduce(0) { $0 + $1.count })")
                        .font(.title2.weight(.bold).monospacedDigit()).foregroundStyle(Brand.ink)
                    if let caption { Text(caption).font(.caption2).foregroundStyle(Brand.textSubtle) }
                }
            }
            .frame(width: 104, height: 104)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(slices) { s in
                    HStack(spacing: 8) {
                        Circle().fill(s.color).frame(width: 10, height: 10)
                        Text("\(s.count)").font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(Brand.ink)
                        Text(s.label).font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.8)) { shown = true } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(slices.map { "\($0.count) \($0.label)" }.joined(separator: ", "))
    }
}

extension SummaryRing.Slice {
    static func alert(_ n: Int, _ label: String) -> Self { .init(label: label, count: n, color: Tone.alert.tint) }
    static func amber(_ n: Int, _ label: String) -> Self { .init(label: label, count: n, color: Color(hex: 0xF2C27A)) }
    static func fine(_ n: Int, _ label: String) -> Self { .init(label: label, count: n, color: Tone.fix.tint) }
}
