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
                    if let comparison = scanner.comparison {
                        Section { ComparisonCard(comparison: comparison) }
                    }
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
                    Section {
                        NavigationLink { ScoreboardView() } label: {
                            Label("iOS scoreboard: what Apple has fixed", systemImage: "checkmark.seal")
                        }
                        NavigationLink { HistoryView() } label: {
                            Label("Your scan history", systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
            }
            .brandListBackground()
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
    @State private var showingFormula = false

    var body: some View {
        VStack(spacing: Brand.Space.md) {
            switch scanner.phase {
            case .idle:
                MascotEmblem(size: 170)
                Text("See what apps can learn about your iPhone, and about you.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
                Text("The scan reads exactly what any app could. Nothing leaves your phone.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textMuted)
                    .multilineTextAlignment(.center)
            case .scanning:
                MascotEmblem(size: 140)
                ProgressView("Looking around…")
                    .padding(.vertical, Brand.Space.sm)
            case .done:
                scoreSummary
            }

            Button {
                Haptics.impact()
                Task {
                    await scanner.scan()
                    Haptics.success()
                }
            } label: {
                Text(scanner.phase == .done ? "Scan again" : "Start scan")
            }
            .buttonStyle(PrimaryCTAButtonStyle())
            .disabled(scanner.phase == .scanning)

            if scanner.phase == .done {
                ShareCardButton()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Brand.Space.sm)
        .sheet(isPresented: $showingFormula) {
            NavigationStack {
                ScrollView {
                    Text(FootprintScore.explanation)
                        .padding()
                }
                .navigationTitle("How the score works")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Done") { showingFormula = false } }
            }
            .presentationDetents([.medium])
        }
    }

    private var scoreSummary: some View {
        let score = scanner.score
        let concerning = scanner.concerning.count
        return VStack(spacing: Brand.Space.sm) {
            HStack(spacing: Brand.Space.lg) {
                ScoreRing(value: score.value)
                    .frame(width: 118, height: 118)
                VStack(alignment: .leading, spacing: 6) {
                    Text(score.level.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                    Text("\(scanner.allFindings.count) things any app could learn. \(concerning == 0 ? "Nothing stands out." : "\(concerning) worth a look.")")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textMuted)
                    if score.reachable > 0 {
                        Text("Fixing \(score.fixableCount) of them could bring you to 100.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Brand.accent)
                    }
                    if score.onlyAppleCount > 0 {
                        Text("\(score.onlyAppleCount) more only Apple can fix.")
                            .font(.footnote)
                            .foregroundStyle(Brand.textSubtle)
                    }
                    Button("How the score works") { showingFormula = true }
                        .font(.footnote)
                        .buttonStyle(.borderless)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .brandCard(padding: Brand.Space.lg)
        }
    }
}

struct ScoreRing: View {
    let value: Int

    var body: some View {
        ZStack {
            Circle().stroke(Brand.border, lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(value) / 100)
                .stroke(AngularGradient(colors: [Brand.glow, Brand.cta, Brand.glow], center: .center),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.8), value: value)
            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(Brand.textPrimary)
                    .contentTransition(.numericText())
                Text("of 100").font(.caption2).foregroundStyle(Brand.textSubtle)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Footprint score \(value) out of 100")
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
                .foregroundStyle(Brand.iconTint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title).foregroundStyle(Brand.textPrimary)
                Text(subtitle(findings))
                    .font(.caption)
                    .foregroundStyle(Brand.textSubtle)
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
                Text(finding.definition.title).foregroundStyle(Brand.textPrimary)
                Text(finding.reading.value)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Brand.textMuted)
                    .lineLimit(2)
                if showSection {
                    Text(finding.definition.section.title)
                        .font(.caption)
                        .foregroundStyle(Brand.textSubtle)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
