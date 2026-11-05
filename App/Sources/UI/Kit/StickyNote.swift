// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// The paper a section is written on (owner, 2026-11-05: every section is a detective's sticky
/// note). Yellow before a check; then the colour of what it found.
enum Paper: CaseIterable, Sendable {
    case yellow, pink, green, blue, purple, gray

    /// The Mac Stickies colours (owner, 2026-11-05). Every ink used on them is measured to reach
    /// WCAG 2.2 AA, 4.5:1 for text and 3:1 for marks, on all six (see Color(dark:paper:)).
    var colour: Color {
        switch self {
        case .yellow: Color(hex: 0xFBEB61)
        case .pink: Color(hex: 0xF3B6B3)
        case .green: Color(hex: 0xA2FC90)
        case .blue: Color(hex: 0xA1EEFD)
        case .purple: Color(hex: 0xA1B5F8)
        case .gray: Color(hex: 0xDADADB)
        }
    }

    /// The paper for a role: coral notes for "worth a look", green for fixes, blue for what a clue
    /// tells an app, yellow for background, gray for "only Apple can fix".
    static func `for`(_ tone: Tone) -> Paper {
        switch tone {
        case .alert: .pink
        case .explain: .blue
        case .context: .yellow
        case .fix: .green
        case .limit: .gray
        }
    }

    /// The paper for a 0–100 score: green when well protected, purple in the middle, pink when heavy; yellow before any check.
    static func `for`(score: Int?) -> Paper {
        guard let score else { return .yellow }
        return score >= 75 ? .green : score >= 50 ? .purple : .pink
    }
}

/// A sticky note: the content on light paper, written in dark ink, pinned or taped, slightly
/// askew. Each note's tilt, fixing and wear come from its seed, so a page never shows two the
/// same and nothing sits perfectly level, yet a note looks the same every time it's drawn.
struct StickyNote: ViewModifier {
    let paper: Paper
    let seed: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The note's height: a tall note tilts less, so no corner swings more than 6 points out.
    @State private var height: CGFloat = 0

    private var hash: UInt64 {
        seed.utf8.reduce(1469598103934665603) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }

    private func capped(_ degrees: Double) -> Double {
        guard height > 24 else { return degrees }
        let limit = asin(min(1, 6 / (height / 2))) * 180 / .pi
        return min(abs(degrees), limit) * (degrees < 0 ? -1 : 1)
    }

    func body(content: Content) -> some View {
        let h = hash
        // Between about -1.2° and +1.2°, never exactly level.
        let steps = [-1.2, -0.9, -0.6, -0.35, 0.35, 0.6, 0.9, 1.2]
        let tilt = steps[Int(h % UInt64(steps.count))]
        let fixing = Int((h >> 8) % 4)          // 0–2 a pin, 3 tape
        let pins: [Color] = [Color(hex: 0xB22222), Color(hex: 0x2B5AA8), Color(hex: 0x2E8A4E), Color(hex: 0xD8B020)]
        let pin = pins[Int((h >> 16) % UInt64(pins.count))]
        let wear = Wear.allCases[Int((h >> 24) % UInt64(Wear.allCases.count))]
        let shape = NoteShape(wear: wear, seed: h)
        content
            .environment(\.colorScheme, .light)
            .background(
                paper.colour   // solid: the measured contrast holds everywhere on the note
                    .overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.03)).frame(height: 14) }
                    .overlay { WearMarks(wear: wear) }
            )
            .clipShape(shape)
            .overlay(alignment: .bottomTrailing) {
                if wear == .curl {      // the rolled-up corner, lit on its back
                    Path { p in p.move(to: CGPoint(x: 30, y: 0)); p.addLine(to: CGPoint(x: 0, y: 30)); p.addLine(to: CGPoint(x: 4, y: 4)); p.closeSubpath() }
                        .fill(paper.colour.opacity(0.95)).shadow(color: .black.opacity(0.35), radius: 2, x: -1, y: -1)
                        .frame(width: 30, height: 30).allowsHitTesting(false)
                }
            }
            .overlay(alignment: .topTrailing) {
                if wear == .dogEar {    // a corner folded over
                    Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 24, y: 24)); p.addLine(to: CGPoint(x: 0, y: 24)); p.closeSubpath() }
                        .fill(.black.opacity(0.16)).frame(width: 24, height: 24).allowsHitTesting(false)
                }
            }
            .overlay(alignment: .top) {
                Group {
                    if fixing == 3 {
                        Rectangle().fill(Color(hex: 0xF3EEDC, alpha: 0.55)).frame(width: 64, height: 18)
                            .rotationEffect(.degrees(-4)).offset(y: -9)
                    } else {
                        Circle().fill(pin).frame(width: 14, height: 14)
                            .overlay(Circle().fill(.white.opacity(0.45)).frame(width: 5, height: 5).offset(x: -2, y: -2))
                            .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1.5)
                            .offset(y: 4)
                    }
                }
                .allowsHitTesting(false)
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.55), radius: 10, x: 2, y: 8)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
            .rotationEffect(.degrees(capped(reduceMotion ? tilt / 2 : tilt)))
            .padding(.vertical, 2)
    }
}

extension View {
    /// Writes this section on a sticky note. Give each call site its own seed; the default is the
    /// caller's file and line, so two notes on a page never match.
    func stickyNote(_ paper: Paper = .yellow, seed: String? = nil, file: String = #fileID, line: Int = #line) -> some View {
        modifier(StickyNote(paper: paper, seed: seed ?? "\(file):\(line)"))
    }
}

/// How a note has aged. Each note gets one, from its seed.
enum Wear: CaseIterable { case torn, cutCorner, curl, dogEar, coffee, aged }

/// The paper's outline: a ragged bottom edge, a snipped corner or a rolled corner; otherwise square.
struct NoteShape: Shape {
    let wear: Wear
    let seed: UInt64
    func path(in r: CGRect) -> Path {
        var p = Path()
        switch wear {
        case .torn:
            p.move(to: r.origin); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 4))
            var x = r.maxX, i: UInt64 = 0
            while x > r.minX {
                i += 1; x -= CGFloat(7 + (seed >> (i % 40)) % 9)
                p.addLine(to: CGPoint(x: max(x, r.minX), y: r.maxY - CGFloat((seed >> ((i * 3) % 50)) % 7)))
            }
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY - 3))
        case .cutCorner:
            p.move(to: CGPoint(x: r.minX + 22, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.minY + 22))
        case .curl:
            p.move(to: r.origin); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 30))
            p.addLine(to: CGPoint(x: r.maxX - 30, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        case .dogEar:
            p.move(to: r.origin); p.addLine(to: CGPoint(x: r.maxX - 24, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY + 24))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        case .coffee, .aged:
            p.addRect(r)
        }
        p.closeSubpath()
        return p
    }
}

/// Marks on the paper itself: a faint coffee ring, or yellowed edges and a crease. Kept light so
/// text over them keeps its contrast.
struct WearMarks: View {
    let wear: Wear
    var body: some View {
        GeometryReader { g in
            switch wear {
            case .coffee:
                Circle().strokeBorder(Color(hex: 0x6E4618, alpha: 0.16), lineWidth: 5)
                    .frame(width: 92, height: 92).position(x: g.size.width - 40, y: g.size.height - 34)
            case .aged:
                ZStack {
                    RoundedRectangle(cornerRadius: 2).strokeBorder(Color(hex: 0x7A5420, alpha: 0.18), lineWidth: 10).blur(radius: 6)
                    Path { p in p.move(to: CGPoint(x: g.size.width * 0.64, y: 0)); p.addLine(to: CGPoint(x: g.size.width * 0.58, y: g.size.height)) }
                        .stroke(Color.black.opacity(0.07), lineWidth: 1.5)
                }
            default: EmptyView()
            }
        }
        .allowsHitTesting(false)
    }
}
