// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct SectionView: View {
    @Environment(Scanner.self) private var scanner
    let section: SignalSection

    private var kind: PermissionKind? {
        PermissionKind.onThisPlatform.first { $0.section == section }
    }

    var body: some View {
        let findings = scanner.findings(in: section)
        let state = kind.map { scanner.permissionStates[$0] ?? .notAsked }
        Page {
            HeroCard(eyebrow: section.group == .permission ? "Needs your permission" : (section.group == .advanced ? "Clever trick" : "Seen without asking"),
                     title: section.title,
                     subtitle: heroLine(findings: findings, state: state),
                     mood: mood(findings: findings, state: state),
                     mascotSize: 100)

            if let kind { permissionCard(kind, hasFindings: !findings.isEmpty) }

            if !findings.isEmpty {
                SectionTitle(title: "On this device")
                Panel {
                    ForEach(findings) { finding in
                        NavigationLink { FindingDetailView(finding: finding) } label: {
                            FindingCard(finding: finding)
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
            } else if kind != nil {
                SectionTitle(title: "What an app would get")
                Panel {
                    ForEach(SignalCatalogue.definitions(in: section)) { def in
                        RowCard(symbol: "eye", title: def.title, subtitle: def.reveals) { EmptyView() }
                    }
                }
            } else {
                MascotSays(line: "Nothing to read here on this device.", mood: .thinking)
            }
        }
        .navigationTitle(section.title)
        .inlineTitle()
    }

    private func heroLine(findings: [Finding], state: PermissionState?) -> String {
        switch state {
        case .notAsked?: return "Here's what any app you allow gets to see."
        case .denied?: return "You said no, so apps you said no to can't see this either."
        case .unavailable?: return "Not available on this device."
        default:
            let worth = findings.filter(\.isConcerning).count
            return worth == 0 ? "\(findings.count) clue\(findings.count == 1 ? "" : "s"), nothing alarming." : "\(findings.count) clues, \(worth) worth a look."
        }
    }

    private func mood(findings: [Finding], state: PermissionState?) -> LivingMascot.Mood {
        if state == .denied { return .happy }
        if state == .notAsked { return .thinking }
        return findings.contains(where: \.isConcerning) ? .concerned : .idle
    }

    @ViewBuilder
    private func permissionCard(_ kind: PermissionKind, hasFindings: Bool) -> some View {
        let state = scanner.permissionStates[kind] ?? .notAsked
        let loading = scanner.loadingPermissions.contains(kind)
        switch state {
        case .notAsked:
            ToneCard(tone: .explain, title: "See it for yourself", symbol: "hand.raised") {
                Text("Tap below and I'll ask the system for the same permission an app would, then show you exactly what it gets. Nothing is saved or sent.")
                    .font(.system(.subheadline))
                    .foregroundStyle(Brand.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await scanner.reveal(kind) }
                } label: {
                    if loading { ProgressView().tint(.white) } else { Text("Show me") }
                }
                .buttonStyle(PrimaryCTAButtonStyle())
                .disabled(loading)
            }
        case .granted, .limited:
            if loading {
                ToneCard(tone: .explain) { HStack { ProgressView(); Text("Reading…").font(.system(.subheadline)) } }
            } else if !hasFindings {
                Button("Show me") { Task { await scanner.reveal(kind) } }
                    .buttonStyle(PrimaryCTAButtonStyle())
            }
            if state == .limited {
                MascotSays(line: "You gave limited access. That's the safer choice.", mood: .happy, size: 70)
            }
        case .denied:
            Button("Change in Settings") { SettingsLink.openOwnPage() }
                .buttonStyle(GhostButtonStyle())
        case .unavailable:
            EmptyView()
        }
    }
}

struct FindingCard: View {
    let finding: Finding

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(finding.definition.title)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textMuted)
                Text(finding.reading.value)
                    .font(.body.weight(.medium).monospacedDigit())
                    .foregroundStyle(Brand.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let note = finding.reading.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(finding.severity == .high ? Brand.concern : Brand.textSubtle)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                if finding.severity == .high { SeverityDot(severity: .high) }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.textSubtle)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) { Rectangle().fill(Brand.border).frame(height: 0.5).padding(.leading, 16) }
    }
}
