// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// What an ink is for, on a sticky note.
enum InkRole: CaseIterable, Sendable {
    case text, muted, subtle, accent, concern, fix, edge, amber, rule
}

extension Paper {
    /// The ink for each role on this paper (owner, 2026-11-06: "the best colour for clear reading").
    /// Designed in OKLCH and measured with the WCAG 2.2 formula: body text is the paper's own hue,
    /// almost black (9 to 13:1); secondary text 7:1 (AAA); hints, headings and the meaning colours
    /// (worth a look, fixed, explains) 6:1; "worth knowing" marks 3.3:1, lighter on purpose so a ring's
    /// segments differ in lightness as well as hue. Gray paper takes a warm charcoal. Source:
    /// internal/drafts/1.0.6-inks/.
    func ink(_ role: InkRole) -> Color {
        let table: [Paper: UInt32] = switch role {
        case .text: [.yellow: 0x25230E, .pink: 0x251010, .green: 0x162414, .blue: 0x042025, .purple: 0x111526, .gray: 0x1A1511]
        case .muted: [.yellow: 0x504D30, .pink: 0x4C2E2D, .green: 0x3D5039, .blue: 0x284E55, .purple: 0x242B43, .gray: 0x49433E]
        case .subtle: [.yellow: 0x59573D, .pink: 0x553938, .green: 0x485944, .blue: 0x36575E, .purple: 0x2F364C, .gray: 0x534C47]
        case .accent: [.yellow: 0x7E4921, .pink: 0x653205, .green: 0x7D4820, .blue: 0x7A451D, .purple: 0x582A00, .gray: 0x744017]
        case .concern: [.yellow: 0x9E2D23, .pink: 0x830D09, .green: 0x9C2C22, .blue: 0x99291F, .purple: 0x740001, .gray: 0x93231A]
        case .fix: [.yellow: 0x0D6332, .pink: 0x014B23, .green: 0x0B6231, .blue: 0x045F2E, .purple: 0x023F1D, .gray: 0x005A2B]
        case .edge: [.yellow: 0x275792, .pink: 0x0D4079, .green: 0x255691, .blue: 0x23538E, .purple: 0x01366E, .gray: 0x1D4E88]
        case .amber: [.yellow: 0xAD721C, .pink: 0x905B00, .green: 0xAC701B, .blue: 0xA86D15, .purple: 0x835201, .gray: 0xA3680A]
        case .rule: [.yellow: 0xA19F82, .pink: 0x9B7B79, .green: 0x8EA28A, .blue: 0x7C9FA6, .purple: 0x707891, .gray: 0x99928C]
        }
        return Color(hex: table[self] ?? 0x26222B)
    }
}

extension EnvironmentValues {
    /// The sticky note a view sits on; nil on the dark page.
    @Entry var paper: Paper? = nil
}

/// A Brand colour that, on a sticky note, becomes the ink measured for that paper; on the dark page
/// it is the usual light colour. Use it anywhere a ShapeStyle goes; `.color` where only a Color will do.
struct InkStyle: ShapeStyle {
    /// nil: a fixed colour that ignores the paper.
    let role: InkRole?
    let color: Color

    init(role: InkRole?, color: Color) { self.role = role; self.color = color }
    /// A fixed colour, for the places that take either.
    init(_ color: Color) { self.init(role: nil, color: color) }
    static let clear = InkStyle(.clear)
    static let white = InkStyle(.white)
    static let black = InkStyle(.black)

    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        if let role, let paper = environment.paper, environment.colorScheme == .light {
            return paper.ink(role).resolve(in: environment)
        }
        return color.resolve(in: environment)
    }

    func opacity(_ value: Double) -> some ShapeStyle { InkOpacity(base: self, amount: value) }
}

private struct InkOpacity: ShapeStyle {
    let base: InkStyle
    let amount: Double
    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        var c = base.resolve(in: environment); c.opacity *= Float(amount); return c
    }
}
