// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// What the score means and how to raise it: shown under the score on the Footprint page.
struct ScoreGuideCard: View {
    let score: FootprintScore
    let fixes: [Finding]
    var all: [Finding] = []
    let onFix: () -> Void

    /// The score if every one of these were fixed.
    private var reachable: Int {
        let ids = Set(fixes.map(\.id))
        return FootprintScore(findings: all.filter { !ids.contains($0.id) }).value
    }

    private var meaning: String {
        switch score.level {
        case .light: "Higher is better, and you're in good shape: apps learn little that could single out this device."
        case .moderate: "Higher is better. You're in the middle: a few clues together could single out this device."
        case .heavy: "Higher is better. A low score means apps can easily tell this device apart from others and recognise you."
        }
    }

    var body: some View {
        ToneCard(tone: fixes.isEmpty ? .fix : .context, title: "What your score means", symbol: "gauge.with.dots.needle.33percent") {
            Text(meaning).font(.subheadline).foregroundStyle(Brand.ink).fixedSize(horizontal: false, vertical: true)
            ScoreBands(value: score.value)
            if fixes.isEmpty {
                Label("Nothing left that you can fix. What remains is up to Apple.", systemImage: "checkmark.seal.fill")
                    .font(.subheadline).foregroundStyle(Tone.fix.tint)
            } else {
                Text("Fix \(fixes.count == 1 ? "this one thing" : "these \(fixes.count) things") and your score could reach \(reachable):")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink).fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(fixes.prefix(5)) { f in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("+\(FootprintScore.points(for: f))").font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(Tone.fix.tint).frame(minWidth: 34, alignment: .leading)
                            Text(f.definition.title).font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if fixes.count > 5 { Text("and \(fixes.count - 5) more").font(.footnote).foregroundStyle(Brand.textSubtle) }
                }
                Button("Fix them with me", action: onFix)
                    .buttonStyle(PrimaryCTAButtonStyle())
            }
        }
    }
}

/// The three bands on one line, with a marker where this device sits.
private struct ScoreBands: View {
    let value: Int

    private func band(_ name: String, _ range: String, _ color: Color, _ align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 1) {
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(color)
            Text(range).font(.caption2).foregroundStyle(Brand.textSubtle)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        Capsule().fill(Tone.alert.tint.opacity(0.55)).frame(width: geo.size.width * 0.5)
                        Capsule().fill(Brand.sand.opacity(0.55)).frame(width: geo.size.width * 0.25 - 2)
                        Capsule().fill(Tone.fix.tint.opacity(0.55))
                    }
                    Circle().fill(Brand.ink).frame(width: 12, height: 12)
                        .offset(x: max(0, min(geo.size.width - 12, geo.size.width * CGFloat(value) / 100 - 6)))
                }
            }
            .frame(height: 12)
            HStack(alignment: .top) {
                band("Heavy", "under 50", Tone.alert.tint, .leading)
                Spacer()
                band("Moderate", "50 to 74", Brand.sand, .center)
                Spacer()
                band("Light", "75 and up", Tone.fix.tint, .trailing)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score \(value) out of 100. Heavy is below 50, moderate 50 to 74, light 75 and above.")
    }
}

/// "Fix them with me": one clue at a time, the steps and the right Settings page, then the next.
/// No app can change these settings for you, so this is the fastest honest way through them.
struct FixWizard: View {
    let fixes: [Finding]
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var done: Set<String> = []

    var body: some View {
        NavigationStack {
            Group {
                if index < fixes.count { step(fixes[index]).id(index).transition(slide) } else { finished.transition(slide) }
            }
            .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: index)
            .navigationTitle(index < fixes.count ? "Fix \(index + 1) of \(fixes.count)" : "All done")
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .sensoryFeedback(.selection, trigger: index)
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 620)
        #endif
    }

    private var slide: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity))
    }

    private func step(_ f: Finding) -> some View {
        Page {
            ProgressView(value: Double(index), total: Double(fixes.count)).tint(Tone.fix.tint)
            Text("Apps can't change these settings for you, so I'll take you to each one. Come back here after each change.")
                .font(.footnote).foregroundStyle(Brand.textSubtle).fixedSize(horizontal: false, vertical: true)
            ToneCard(tone: .fix, title: f.definition.title, symbol: "wrench.and.screwdriver") {
                ToneBadge(text: "+\(FootprintScore.points(for: f)) points", tone: .fix)
            } content: {
                Text(f.definition.fix.summary).font(.body).foregroundStyle(Brand.ink).fixedSize(horizontal: false, vertical: true)
                if !f.definition.fix.steps.isEmpty { StepList(steps: f.definition.fix.steps, tint: Tone.fix.tint) }
                #if os(macOS)
                if let pane = f.definition.fix.settingsPane {
                    Button("Open in System Settings") { SettingsLink.open(pane: pane) }.buttonStyle(GhostButtonStyle())
                }
                #else
                Button("Open Settings") { SettingsLink.openSettingsHome() }.buttonStyle(GhostButtonStyle()).frame(maxWidth: .infinity)
                #endif
            }
            Button("Done, next") { done.insert(f.id); Haptics.success(); index += 1 }
                .buttonStyle(PrimaryCTAButtonStyle(fill: Brand.green, depthColor: Color(hex: 0x0E8A56)))
            Button("Skip this one") { index += 1 }
                .buttonStyle(GhostButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }

    private var finished: some View {
        Page {
            MascotSays(line: done.isEmpty ? "No changes this time. You can come back whenever you like." :
                        "Nice work: you changed \(done.count) setting\(done.count == 1 ? "" : "s"). Scan again to see your new score.",
                       mood: .happy, size: 72, tone: .fix)
            Button("Scan again") { dismiss(); onFinish() }
                .buttonStyle(PrimaryCTAButtonStyle())
        }
    }
}
