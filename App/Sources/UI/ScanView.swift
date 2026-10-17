// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct ScanView: View {
    @Environment(Scanner.self) private var scanner

    var body: some View {
        NavigationStack {
            List {
                Section { ScanHeader() }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                if scanner.phase == .done {
                    if !scanner.concerning.isEmpty {
                        Section {
                            ForEach(scanner.concerning) { finding in
                                NavigationLink { FindingDetailView(finding: finding) } label: {
                                    FindingRow(finding: finding, showSection: true)
                                }
                            }
                        } header: {
                            Text("Worth a look")
                        } footer: {
                            Text("The details that make your iPhone easiest to recognise, or that say something personal.")
                        }
                    }
                    sectionGroup(.passive, title: "What any app sees without asking",
                                 footer: "No prompt, no permission. Every app on your phone can read these.")
                    sectionGroup(.advanced, title: "Clever tricks",
                                 footer: "Ordinary features used in ways they weren't meant for.")
                    sectionGroup(.permission, title: "What apps see once you say yes",
                                 footer: "Tap a category to see what an app with that permission gets. We ask only when you tap Show me.")
                }
            }
            .navigationTitle("Footprint Inspector")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func sectionGroup(_ group: SignalGroup, title: String, footer: String) -> some View {
        Section {
            ForEach(SignalSection.allCases.filter { $0.group == group }) { section in
                NavigationLink { SectionView(section: section) } label: {
                    SectionRow(section: section)
                }
            }
        } header: {
            Text(title)
        } footer: {
            Text(footer)
        }
    }
}

private struct ScanHeader: View {
    @Environment(Scanner.self) private var scanner

    var body: some View {
        VStack(spacing: 14) {
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityHidden(true)

            switch scanner.phase {
            case .idle:
                Text("See what apps can learn about your iPhone, and about you.")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("The scan reads exactly what any app could. Nothing leaves your phone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .scanning:
                ProgressView("Looking around…")
            case .done:
                summary
            }

            Button {
                Task { await scanner.scan() }
            } label: {
                Text(scanner.phase == .done ? "Scan again" : "Start scan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(Brand.blue)
            .disabled(scanner.phase == .scanning)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var summary: some View {
        let total = scanner.allFindings.count
        let concerning = scanner.concerning.count
        return VStack(spacing: 4) {
            Text("\(total) things any app could learn")
                .font(.title3.weight(.semibold))
            Text(concerning == 0
                 ? "Nothing stands out right now."
                 : "\(concerning) \(concerning == 1 ? "is" : "are") worth a look. Most of the rest are ordinary.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct SectionRow: View {
    @Environment(Scanner.self) private var scanner
    let section: SignalSection

    var body: some View {
        let findings = scanner.findings(in: section)
        let top = findings.map(\.severity).max() ?? .low
        HStack(spacing: 12) {
            Image(systemName: section.symbol)
                .foregroundStyle(Brand.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                Text(subtitle(findings))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !findings.isEmpty { SeverityDot(severity: top) }
        }
    }

    private func subtitle(_ findings: [Finding]) -> String {
        if let kind = PermissionKind.allCases.first(where: { $0.section == section }) {
            switch scanner.permissionStates[kind] {
            case .granted?, .limited?: break
            case .denied?: return "You said no. Nothing to see."
            case .unavailable?: return "Not available on this device"
            default: return "Tap to see what an app would get"
            }
        }
        return findings.isEmpty ? "Nothing read" : "\(findings.count) detail\(findings.count == 1 ? "" : "s")"
    }
}

struct FindingRow: View {
    let finding: Finding
    var showSection = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            SeverityDot(severity: finding.severity)
            VStack(alignment: .leading, spacing: 3) {
                Text(finding.definition.title)
                Text(finding.reading.value)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if showSection {
                    Text(finding.definition.section.title)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
