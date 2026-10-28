// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct ScanView: View {
    @Environment(Scanner.self) private var scanner
    /// The open finding or category, saved on this device so it's still open after iOS quits the
    /// app while the person changes a setting. Screenshot runs can open one with `-openFinding <id>`.
    @AppStorage("nav.finding") private var openedFinding = ""
    @AppStorage("nav.section") private var openedSection = ""

    private func stored(_ value: Binding<String>) -> Binding<String?> {
        Binding(get: { value.wrappedValue.isEmpty ? nil : value.wrappedValue }, set: { value.wrappedValue = $0 ?? "" })
    }

    var body: some View {
        NavigationStack {
            Page(resetOn: AnyHashable("\(scanner.phase)")) {
                switch scanner.phase {
                case .idle: IdleHome()
                case .scanning: ScanningView()
                case .done: Results(openFinding: { openedFinding = $0 }, openSection: { openedSection = $0 })
                }
            }
            .hiddenNavigationBar()
            .task {
                if LaunchOptions.autoScan, scanner.allFindings.isEmpty { await scanner.scan() }
                if let id = LaunchOptions.value(after: "-openFinding") { openedFinding = id }
            }
            .navigationDestination(item: stored($openedFinding)) { id in
                if let finding = scanner.allFindings.first(where: { $0.id == id }) {
                    FindingDetailView(finding: finding)
                } else {
                    ProgressView().tint(Brand.ink)
                }
            }
            .navigationDestination(item: stored($openedSection)) { id in
                if let section = SignalSection(rawValue: id) { SectionView(section: section) }
            }
            .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: Int(scanner.progress * 16))
            .sensoryFeedback(trigger: scanner.phase) { _, new in
                guard new == .done else { return nil }
                return scanner.concerning.isEmpty ? .success : .warning
            }
            .animation(.easeInOut(duration: 0.35), value: scanner.phase)
        }
    }
}

// MARK: - Before the first scan

private struct IdleHome: View {
    @Environment(Scanner.self) private var scanner
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var short: Bool { verticalSizeClass == .compact }
    #else
    private let short = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: short ? 14 : 24) {
            if !short {
                LivingMascot(mood: .idle, size: 180)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            }
            // Sideways on a phone the mascot sits beside the heading, so the scan button
            // stays above the tab bar.
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Brand.eyebrow("Check 1 · Footprint")
                    AccentRule()
                    Text("What can any app read about this device?")
                        .scaledFont(30, weight: .bold, relativeTo: .largeTitle)
                        .foregroundStyle(Brand.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("A quick scan reads only what any app could, without asking you. Then I'll help you fix what you can.")
                        .font(.body)
                        .foregroundStyle(Brand.textMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if short { LivingMascot(mood: .idle, size: 90) }
            }
            VStack(spacing: 14) {
                Button("Start with check 1") { Task { await scanner.scan() } }
                    .buttonStyle(PrimaryCTAButtonStyle())
                Text("Nothing leaves your device · Open source")
                    .font(.footnote)
                    .foregroundStyle(Brand.textSubtle)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - While scanning

private struct ScanningView: View {
    @Environment(Scanner.self) private var scanner

    var body: some View {
        VStack(spacing: 28) {
            LivingMascot(mood: .scanning, size: 200)
                .padding(.top, 60)
            VStack(spacing: 10) {
                Text(Self.line(for: scanner.progress))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: Self.line(for: scanner.progress))
                ProgressView(value: scanner.progress)
                    .tint(Brand.ink)
                    .frame(width: 180)
                Text("Reading only what any app could. Nothing is sent anywhere.")
                    .font(.footnote)
                    .foregroundStyle(Brand.textSubtle)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    static func line(for p: Double) -> String {
        switch p {
        case ..<0.25: "Looking for fingerprints…"
        case ..<0.5: "Checking your settings…"
        case ..<0.75: "Reading the sensors…"
        default: "Writing up the case…"
        }
    }
}

// MARK: - Results

private struct Results: View {
    let openFinding: (String) -> Void
    let openSection: (String) -> Void
    @Environment(Scanner.self) private var scanner
    @State private var showingFormula = false
    /// Saved on this device, like the open page, so the walk-through is still open on return.
    @AppStorage("nav.fixing") private var fixing = false
    /// The clues you can fix, most points first.
    private var fixes: [Finding] {
        scanner.concerning.filter { FootprintScore.isFixable($0) && FootprintScore.points(for: $0) > 0 }
            .sorted { FootprintScore.points(for: $0) > FootprintScore.points(for: $1) }
    }
    @Environment(\.goToTab) private var goToTab

    var body: some View {
        let score = scanner.score
        let concerning = scanner.concerning

        // Check 1 in detail: the footprint score and its clues. The overall score is on the Score page.
        Color.clear.frame(height: 4)
            .sheet(isPresented: $showingFormula) { FormulaSheet() }
            .sheet(isPresented: $fixing, onDismiss: { FixWizard.forget(); Task { await scanner.scan(quietly: true) } }) { FixWizard(fixes: fixes) }

        VStack(alignment: .leading, spacing: 14) {
            Brand.eyebrow("Check 1 · Footprint")
                .padding(.top, 20)
            Text("\(score.level.title): \(score.value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.ink)
            Text("Any app can read \(scanner.allFindings.count) clues about this device. \(concerning.isEmpty ? "None stands out." : "\(concerning.count) are worth a look.")")
                .font(.body)
                .foregroundStyle(Brand.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            let seen = scanner.allFindings
            SummaryRing(slices: [
                .alert(seen.filter { $0.severity == .high }.count, "worth a look"),
                .amber(seen.filter { $0.severity == .medium }.count, "worth knowing"),
                .fine(seen.filter { $0.severity == .low }.count, "minor"),
            ], caption: "clues")
            Button("Scan again") { Task { await scanner.scan() } }
                .buttonStyle(PrimaryCTAButtonStyle())
            Button("How the score works") { showingFormula = true }
                .buttonStyle(.plain)
                .font(.footnote)
                .foregroundStyle(Brand.textSubtle)
                .frame(maxWidth: .infinity)
        }

        ScoreGuideCard(score: score, fixes: fixes, all: scanner.allFindings) { FixWizard.forget(); fixing = true }
            .task { if LaunchOptions.has("-openFix") && !fixes.isEmpty { FixWizard.forget(); fixing = true } }


        SectionDivider()

        if let comparison = scanner.comparison {
            ToneCard(tone: .context) { ComparisonCard(comparison: comparison) }
        }

        if !concerning.isEmpty {
            SectionTitle(title: "Worth a look", trailing: "\(concerning.count)")
            Panel {
                ForEach(concerning) { finding in
                    Button { openFinding(finding.id) } label: {
                        ClueRow(finding: finding)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }

        group(.passive, title: "Seen without asking")
        group(.advanced, title: "Clever tricks")
        group(.permission, title: "Seen once you allow it")

        // Rating, scan history and the scoreboard live in Settings, not on a check's page.
        NextStepCard(step: .sensitive) { goToTab(.sensitive) }
    }

    @ViewBuilder
    private func group(_ group: SignalGroup, title: String) -> some View {
        SectionTitle(title: title)
        Panel {
            ForEach(SignalSection.onThisPlatform.filter { $0.group == group }) { section in
                Button { openSection(section.rawValue) } label: {
                    CategoryTile(section: section)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }
}

struct ClueRow: View {
    let finding: Finding

    var body: some View {
        let fixable = finding.definition.fix.level != .onlyApple
        RowCard(symbol: finding.definition.section.symbol,
                title: finding.definition.headline,
                subtitle: fixable ? "You can fix this" : "Only Apple can fix this",
                tileFG: Brand.concern) {
            HStack(spacing: 8) {
                SeverityDot(severity: finding.severity)
                Image(systemName: "chevron.right")
            }
        }
    }
}

/// A category as a list row: icon, name, how many clues, and a dot when something stands out.
struct CategoryTile: View {
    @Environment(Scanner.self) private var scanner
    let section: SignalSection

    var body: some View {
        let findings = scanner.findings(in: section)
        let top = findings.map(\.severity).max() ?? .low
        RowCard(symbol: section.symbol, title: section.title) {
            HStack(spacing: 8) {
                Text(detail(findings))
                if top == .high { SeverityDot(severity: .high) }
                Image(systemName: "chevron.right")
            }
        }
    }

    private func detail(_ findings: [Finding]) -> String {
        if let kind = PermissionKind.onThisPlatform.first(where: { $0.section == section }) {
            switch scanner.permissionStates[kind] {
            case .granted?, .limited?: break
            case .denied?: return "Off"
            case .unavailable?: return "N/A"
            default: return "See"
            }
        }
        return findings.isEmpty ? "–" : "\(findings.count)"
    }
}

struct FormulaSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Page {
                MascotSays(line: "No secret maths. Here's exactly how I score.", mood: .thinking)
                ToneCard(tone: .context, title: "Your privacy score", symbol: "function") { Text(OverallScore.explanation).font(.body).foregroundStyle(Brand.textMuted).lineSpacing(3).fixedSize(horizontal: false, vertical: true) }
                ToneCard(tone: .context, title: "The footprint score in detail", symbol: "pawprint") { Text(FootprintScore.explanation).font(.body).foregroundStyle(Brand.textMuted).lineSpacing(3).fixedSize(horizontal: false, vertical: true) }
            }
            .navigationTitle("How the score works")
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Label("Done", systemImage: "checkmark") }
                }
            }
        }
        .presentationDetents([.large])
    }
}
