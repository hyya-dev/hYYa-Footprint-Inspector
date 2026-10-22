// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

// MARK: - Page scaffold

/// Every screen: black ground, one generous column, room for the tab bar.
struct Page<Content: View>: View {
    var spacing: CGFloat = 24
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            // A comfortable reading width on iPad; full width on iPhone.
            .frame(maxWidth: 720)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(BrandBackground())
        // Content fades out under the status bar instead of colliding with the clock.
        .overlay(alignment: .top) {
            LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: 64)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }
}

/// The top of a page: a quiet eyebrow, a large title, a short line, and the mascot beside it.
/// No panel and no box: type and space do the work.
struct HeroCard<Trailing: View>: View {
    var eyebrow: String? = nil
    var title: String
    var subtitle: String? = nil
    var mood: LivingMascot.Mood = .idle
    var mascotSize: CGFloat = 110
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    if let eyebrow { Brand.eyebrow(eyebrow) }
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Brand.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                LivingMascot(mood: mood, size: mascotSize)
            }
            AccentRule()
            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(Brand.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            trailing
        }
        .padding(.top, 4)
    }
}

extension HeroCard where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String, subtitle: String? = nil, mood: LivingMascot.Mood = .idle, mascotSize: CGFloat = 110) {
        self.init(eyebrow: eyebrow, title: title, subtitle: subtitle, mood: mood, mascotSize: mascotSize) { EmptyView() }
    }
}

// MARK: - Panels and rows

/// A quiet near-black panel that groups rows, like a grouped list.
struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        VStack(alignment: .leading, spacing: 0) { content }
            .background(
                shape.fill(Brand.surface)
                    .overlay(shape.fill(LinearGradient(colors: [Brand.sand.opacity(0.06), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35))))
            )
            .clipShape(shape)
            .overlay(shape.strokeBorder(LinearGradient(colors: [Brand.sandDeep.opacity(0.7), Brand.sandDeep.opacity(0.18)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75))
    }
}

/// A short sand rule that marks the start of content, like a pen stroke under a heading.
struct AccentRule: View {
    var width: CGFloat = 36
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [Brand.sand, Brand.sandDeep], startPoint: .leading, endPoint: .trailing))
            .frame(width: width, height: 3)
            .accessibilityHidden(true)
    }
}

/// A full-width hairline separator between parts of a page.
struct SectionDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Brand.rule).frame(height: 0.5)
            Image(systemName: "pawprint.fill").font(.system(size: 8)).foregroundStyle(Brand.sandDeep)
            Rectangle().fill(Brand.rule).frame(height: 0.5)
        }
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }
}

/// A list row: a small icon, a title, an optional line beneath, an accessory, a hairline below.
struct RowCard<Accessory: View>: View {
    let symbol: String
    let title: String
    var subtitle: String? = nil
    var tileFG: Color = Brand.sand
    var tileBG: Color = .clear
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(tileFG)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tileFG.opacity(0.10)))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(tileFG.opacity(0.22), lineWidth: 0.5))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Brand.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Brand.textSubtle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            accessory
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.textSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle().fill(Brand.rule).frame(height: 0.5).padding(.leading, 62)
        }
    }
}

extension RowCard where Accessory == Image {
    init(symbol: String, title: String, subtitle: String? = nil, tileFG: Color = Brand.sand, tileBG: Color = .clear) {
        self.init(symbol: symbol, title: title, subtitle: subtitle, tileFG: tileFG, tileBG: tileBG) {
            Image(systemName: "chevron.right")
        }
    }
}

/// A small grey label above a group, like a grouped list header.
struct SectionTitle: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(Brand.brandUppercased(title))
                .font(.caption.weight(.semibold))
                .tracking(1)
                .foregroundStyle(Brand.sand)
            Rectangle().fill(Brand.rule).frame(height: 0.5)
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Brand.sand)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Brand.sandSoft))
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, -14)
    }
}

// MARK: - Mascot that talks on a page

/// The mascot with something to say, inside its own card: the text gets the card's full width
/// instead of a narrow bubble beside the mascot.
struct MascotSays: View {
    var line: String
    var mood: LivingMascot.Mood = .idle
    var size: CGFloat = 72
    var title: String? = nil
    var tone: Tone = .explain

    var body: some View {
        ToneCard(tone: tone, title: title, symbol: title == nil ? nil : "text.bubble") {
            HStack(alignment: .top, spacing: 14) {
                LivingMascot(mood: mood, size: min(size, 64))
                    .accessibilityHidden(true)
                Text(line)
                    .font(.body)
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Score ring

/// A thin ring with the score set in large light type. One faint highlight, nothing more.
struct ScoreOrb: View {
    let value: Int
    var size: CGFloat = 132
    var tint: Color = Brand.sand

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(value) / 100)
                .stroke(LinearGradient(colors: [tint, Color.white], startPoint: .bottomLeading, endPoint: .topTrailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .neonGlow(tint, radius: 8, intensity: 0.6)
                .animation(.spring(response: 0.9, dampingFraction: 0.85), value: value)
            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.system(size: size * 0.38, weight: .light))
                    .foregroundStyle(Brand.ink)
                    .contentTransition(.numericText(value: Double(value)))
                Text("of 100")
                    .font(.caption)
                    .foregroundStyle(Brand.textSubtle)
            }
        }
        .frame(width: size, height: size)
        .tiltParallax(6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Footprint score \(value) out of 100")
    }
}

// MARK: - Bits

/// A small status label: coloured text on a barely-there fill.
struct Pill: View {
    let text: String
    var symbol: String? = nil
    var fg: Color = Brand.textMuted
    var bg: Color = Color.white.opacity(0.06)

    var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol).font(.caption2) }
            Text(text).lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(fg)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(bg))
    }
}

/// A small icon. Kept for call sites that want an icon with a soft square behind it.
struct IconTile: View {
    let symbol: String
    var fg: Color = Brand.textMuted
    var bg: Color = Color.white.opacity(0.06)
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42))
            .foregroundStyle(fg)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).fill(bg))
    }
}

/// Numbered steps.
struct StepList: View {
    let steps: [String]
    var tint: Color = Brand.sand

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(i + 1)")
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(tint)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(tint.opacity(0.10)))
                        .overlay(Circle().strokeBorder(tint.opacity(0.5), lineWidth: 0.75))
                    Text(step)
                        .font(.body)
                        .foregroundStyle(Brand.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
