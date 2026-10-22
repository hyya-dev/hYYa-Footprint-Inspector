// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct FindingDetailView: View {
    @Environment(Scanner.self) private var scanner
    @Environment(\.openURL) private var openURL
    @AppStorage(HyyaSuggestions.settingKey) private var showSuggestions = true
    let finding: Finding
    @State private var cleared = false
    @State private var showDetails = false

    private var def: SignalDefinition { finding.definition }
    private var fixable: Bool { def.fix.level != .onlyApple }

    private var headerTone: Tone { finding.severity == .high ? .alert : .context }

    var body: some View {
        Page {
            // The clue itself.
            ToneCard(tone: headerTone) {
                HStack(alignment: .center) {
                    ToneBadge(text: finding.severity == .high ? "Worth a look" : finding.severity.label,
                              symbol: finding.severity == .high ? "exclamationmark.circle.fill" : "circle.fill", tone: headerTone)
                    Spacer(minLength: 8)
                    StatusBadge(status: def.status)
                }
                Text(def.title)
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(Brand.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(Brand.brandUppercased("On your device"))
                        .font(.caption.weight(.semibold))
                        .tracking(1.1)
                        .foregroundStyle(Brand.textSubtle)
                    Text(finding.reading.value)
                        .font(.title2.weight(.light).monospacedDigit())
                        .foregroundStyle(Brand.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                if let note = finding.reading.note {
                    Label {
                        Text(note).fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: finding.severity == .high ? "exclamationmark.triangle.fill" : "info.circle")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(finding.severity == .high ? Tone.alert.tint : Brand.textMuted)
                }
                FlowRow {
                    ToneBadge(text: def.persistence.label, symbol: "clock", tone: .limit)
                    ToneBadge(text: def.section.group == .permission ? "Needs permission" : "No permission needed",
                              symbol: def.section.group == .permission ? "hand.raised" : "eye", tone: .limit)
                }
                if !finding.reading.items.isEmpty {
                    Rectangle().fill(headerTone.tint.opacity(0.2)).frame(height: 0.5)
                    DisclosureGroup(isExpanded: $showDetails) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(finding.reading.items.enumerated()), id: \.offset) { _, item in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Circle().fill(headerTone.tint.opacity(0.7)).frame(width: 5, height: 5)
                                    Text(item)
                                        .font(.subheadline)
                                        .foregroundStyle(Brand.textMuted)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .textSelection(.enabled)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("All the details (\(finding.reading.items.count))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(headerTone.tint)
                    }
                    .tint(headerTone.tint)
                    .sensoryFeedback(.selection, trigger: showDetails)
                }
            }

            seriousCard

            MascotSays(line: def.reveals, mood: finding.severity == .high ? .concerned : .thinking, size: 64,
                       title: "What it tells an app", tone: .explain)

            ToneCard(tone: .context, title: "Why the system allows it", symbol: "questionmark.circle") {
                Text(def.why)
                    .font(.body)
                    .foregroundStyle(Brand.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            fixCard

            if showSuggestions, let suggestion = HyyaSuggestions.suggestion(for: def.id) {
                ToneCard(tone: .context, title: "From the makers of this app", symbol: "sparkles") {
                    Text(suggestion.reason).font(.body).foregroundStyle(Brand.textMuted)
                    Button("Open \(suggestion.appName)") { openURL(suggestion.url) }
                        .buttonStyle(GhostButtonStyle())
                }
            }
        }
        // The card carries the full title; a bar title would only repeat it, cut short.
        .navigationTitle("")
        .inlineTitle()
    }

    /// How serious it is: a level, who can read it, how long it lasts and what it lets someone do.
    private var seriousCard: some View {
        let level = SignalImpact.level(finding.severity)
        let tone: Tone = finding.severity == .high ? .alert : (finding.severity == .medium ? .context : .limit)
        return ToneCard(tone: tone, title: "How serious", symbol: "gauge.with.dots.needle.67percent") {
            ToneBadge(text: level.rawValue, tone: tone)
        } content: {
            if let line = SignalImpact.inPractice[def.id] {
                Text(line)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            impactRow("eye", "Who can read it",
                      def.section.group == .permission ? "Only apps you've given this permission." : "Any app on this device, without asking you.")
            impactRow("clock", "How long it lasts", SignalImpact.lasting(def.persistence))
            impactRow("link", "What it lets them do", SignalImpact.reach(finding.severity))
        }
    }

    private func impactRow(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol).font(.subheadline).foregroundStyle(Brand.textSubtle).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                Text(text).font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var fixCard: some View {
        ToneCard(tone: fixable ? .fix : .limit,
                 title: fixable ? "How to fix it" : "Only Apple can fix this",
                 symbol: fixable ? "wrench.and.screwdriver" : "lock") {
            if fixable && finding.severity == .high {
                ToneBadge(text: "+\(FootprintScore.highWeight) points", tone: .fix)
            }
        } content: {
            Text(def.fix.summary)
                .font(.body)
                .foregroundStyle(Brand.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            if !def.fix.steps.isEmpty {
                StepList(steps: def.fix.steps, tint: fixable ? Tone.fix.tint : Tone.limit.tint)
            }
            if def.id == "clip-kinds" || def.id == "mac-clipboard" {
                Button(cleared ? "Clipboard cleared" : "Clear the clipboard now") {
                    #if os(iOS)
                    UIPasteboard.general.items = []
                    #else
                    NSPasteboard.general.clearContents()
                    #endif
                    cleared = true
                    Haptics.success()
                    Task { await scanner.scan() }
                }
                .buttonStyle(PrimaryCTAButtonStyle(fill: Brand.green, depthColor: Color(hex: 0x0E8A56)))
                .disabled(cleared)
            }
            if fixable {
                #if os(macOS)
                if let pane = def.fix.settingsPane {
                    Button("Open in System Settings") { SettingsLink.open(pane: pane) }
                        .buttonStyle(PrimaryCTAButtonStyle())
                } else {
                    Button("Open System Settings") { SettingsLink.openSettingsHome() }
                        .buttonStyle(GhostButtonStyle())
                        .frame(maxWidth: .infinity)
                }
                #else
                Button("Open Settings") { SettingsLink.openSettingsHome() }
                    .buttonStyle(PrimaryCTAButtonStyle())
                #endif
            }
        }
    }
}
