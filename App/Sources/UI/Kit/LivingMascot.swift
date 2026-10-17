// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// The detective, alive on every page: he breathes, floats, leans with the phone in 3D, reacts to
/// what's on screen and says something useful in a speech bubble. Tap him for a tip.
struct LivingMascot: View {
    enum Mood: Equatable {
        /// Waiting, gently floating.
        case idle
        /// Busy looking: quick wiggle.
        case scanning
        /// Good news: a hop.
        case happy
        /// Something worth a look: leans in.
        case concerned
        /// Reading the details: slight head tilt.
        case thinking
    }

    var mood: Mood = .idle
    var size: CGFloat = 140
    /// What he says. `nil` hides the bubble.
    var line: String? = nil
    /// Where the bubble sits.
    var bubbleOnLeading = false
    /// Tips he offers when tapped.
    var tips: [String] = LivingMascot.defaultTips

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tipIndex = -1
    @State private var hop = false
    @State private var tapCount = 0

    static let defaultTips = [
        "Every app can read what I read. That's the point.",
        "Restarting your phone gives some clues a fresh value.",
        "Fewer apps installed means fewer clues to find.",
        "I never send anything anywhere. Promise.",
    ]

    private var shownLine: String? {
        tipIndex >= 0 ? tips[tipIndex % tips.count] : line
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if bubbleOnLeading, let text = shownLine { bubble(text, tailOnTrailing: true) }
            figure
            if !bubbleOnLeading, let text = shownLine { bubble(text, tailOnTrailing: false) }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: shownLine)
    }

    private var figure: some View {
        Button(action: poke) { animatedFigure }
            .buttonStyle(.plain)
            .frame(width: size, height: size * 1.06)
            .contentShape(Rectangle())
            .onChange(of: mood) { _, new in
                if new == .happy { jump() }
            }
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: tapCount)
            .accessibilityLabel("The hYYa Footprint Inspector detective")
            .accessibilityHint("Double-tap for a tip")
    }

    /// The drawing itself never takes touches: the 3D transforms inside it made its hit area
    /// unreliable on device and in the Simulator, so taps meant for nearby buttons reached him.
    private var animatedFigure: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let float = reduceMotion ? 0 : sin(t * 1.6) * size * 0.025
            let breathe = reduceMotion ? 1 : 1 + sin(t * 2.1) * 0.012
            let wiggle = mood == .scanning && !reduceMotion ? sin(t * 14) * 5 : 0
            let lean: Double = switch mood {
            case .concerned: -6
            case .thinking: 5
            default: 0
            }
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: size * 0.62, height: size * 0.09)
                    .blur(radius: 6)
                    .scaleEffect(1 - float / size * 2)
                    .offset(y: size * 0.04)
                Image("MascotCutout")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    // Rim-lit by the screen: cyan normally, orange when something is worth a look.
                    .neonGlow(mood == .concerned ? Brand.orange : Brand.sand, radius: size * 0.08, intensity: 0.35)
                    .scaleEffect(breathe)
                    .rotationEffect(.degrees(wiggle + lean), anchor: .bottom)
                    .offset(y: float - (hop ? size * 0.12 : 0))
                    .tiltParallax(10)
            }
            .frame(width: size, height: size * 1.06)
        }
        .allowsHitTesting(false)
    }

    private func bubble(_ text: String, tailOnTrailing: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Brand.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.surfaceRaised)

            )
            .overlay(alignment: tailOnTrailing ? .trailing : .leading) {
                BubbleTail()
                    .fill(Brand.surfaceRaised)
                    .frame(width: 12, height: 14)
                    .rotationEffect(.degrees(tailOnTrailing ? 180 : 0))
                    .offset(x: tailOnTrailing ? 9 : -9, y: 4)
            }
            .frame(maxWidth: 220, alignment: tailOnTrailing ? .trailing : .leading)
            .padding(.top, size * 0.12)
            .transition(.scale(scale: 0.6, anchor: tailOnTrailing ? .trailing : .leading).combined(with: .opacity))
            .id(text)
    }

    private func poke() {
        tapCount += 1
        tipIndex += 1
        jump()
    }

    private func jump() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { hop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { hop = false }
        }
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
