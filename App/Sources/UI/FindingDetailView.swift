// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import UIKit

struct FindingDetailView: View {
    @Environment(Scanner.self) private var scanner
    @Environment(\.openURL) private var openURL
    @AppStorage(HyyaSuggestions.settingKey) private var showSuggestions = true
    let finding: Finding
    @State private var cleared = false
    @State private var showDetails = false

    private var def: SignalDefinition { finding.definition }
    private var fixable: Bool { def.fix.level != .onlyApple }

    var body: some View {
        Page {
            // The clue itself, on a 3D card.
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Pill(text: finding.severity == .high ? "Worth a look" : finding.severity.label,
                         fg: finding.severity == .high ? Brand.concern : Brand.accent,
                         bg: Brand.fill(for: finding.severity))
                    Spacer()
                    StatusBadge(status: def.status)
                }
                Text(def.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Brand.textPrimary)
                Text("On your iPhone")
                    .font(.system(.caption).weight(.bold))
                    .foregroundStyle(Brand.textSubtle)
                Text(finding.reading.value)
                    .font(.title2.weight(.light).monospacedDigit())
                    .foregroundStyle(Brand.ink)
                    .textSelection(.enabled)
                if let note = finding.reading.note {
                    Text(note)
                        .font(.system(.subheadline).weight(.semibold))
                        .foregroundStyle(finding.severity == .high ? Brand.concern : Brand.textMuted)
                }
                HStack(spacing: 8) {
                    Pill(text: def.persistence.label, symbol: "clock", fg: Brand.textMuted, bg: Brand.surfaceRaised)
                    Pill(text: def.section.group == .permission ? "Needs permission" : "No permission needed",
                         symbol: def.section.group == .permission ? "hand.raised" : "eye", fg: Brand.textMuted, bg: Brand.surfaceRaised)
                }
                if !finding.reading.items.isEmpty {
                    DisclosureGroup(isExpanded: $showDetails) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(finding.reading.items.enumerated()), id: \.offset) { _, item in
                                Text(item)
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(Brand.textMuted)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.top, 6)
                    } label: {
                        Text("All the details (\(finding.reading.items.count))")
                            .font(.system(.subheadline).weight(.bold))
                            .foregroundStyle(Brand.accent)
                    }
                    .sensoryFeedback(.selection, trigger: showDetails)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)

            MascotSays(line: def.reveals, mood: finding.severity == .high ? .concerned : .thinking, size: 78)

            InfoCard(title: "Why iPhone allows it", symbol: "questionmark.circle") {
                Text(def.why).font(.system(.body)).foregroundStyle(Brand.textMuted)
            }

            fixCard

            if showSuggestions, let suggestion = HyyaSuggestions.suggestion(for: def.id) {
                InfoCard(title: "From the makers of this app", symbol: "sparkles") {
                    Text(suggestion.reason).font(.system(.body))
                    Button("Open \(suggestion.appName)") { openURL(suggestion.url) }
                        .buttonStyle(GhostButtonStyle())
                }
            }
        }
        .navigationTitle(def.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fixCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(fixable ? "How to fix it" : "Only Apple can fix this")
                    .font(Brand.display(22))
                    .foregroundStyle(Brand.ink)
                Spacer()
                if fixable && finding.severity == .high {
                    Pill(text: "+\(FootprintScore.highWeight)", fg: Brand.orange, bg: Brand.sunflowerSoft)
                }
            }
            Text(def.fix.summary)
                .font(.system(.body))
                .foregroundStyle(Brand.textMuted)
            if !def.fix.steps.isEmpty {
                StepList(steps: def.fix.steps)
            }
            if def.id == "clip-kinds" {
                Button(cleared ? "Clipboard cleared" : "Clear the clipboard now") {
                    UIPasteboard.general.items = []
                    cleared = true
                    Haptics.success()
                    Task { await scanner.scan() }
                }
                .buttonStyle(PrimaryCTAButtonStyle(fill: Brand.green, depthColor: Color(hex: 0x0E8A56)))
                .disabled(cleared)
            }
            if fixable {
                Button("Open Settings") { SettingsLink.openSettingsHome() }
                    .buttonStyle(GhostButtonStyle())
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.surface))
    }
}
