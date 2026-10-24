// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct ScanView: View {
    @Environment(Scanner.self) private var scanner
    /// Screenshot runs can open one finding with `-openFinding <id>`.
    @State private var openedFindingID: String?

    var body: some View {
        NavigationStack {
            Page(resetOn: AnyHashable("\(scanner.phase)")) {
                switch scanner.phase {
                case .idle: IdleHome()
                case .scanning: ScanningView()
                case .done: Results()
                }
            }
            .hiddenNavigationBar()
            .task {
                if LaunchOptions.autoScan, scanner.allFindings.isEmpty { await scanner.scan() }
                openedFindingID = LaunchOptions.value(after: "-openFinding")
            }
            .navigationDestination(item: $openedFindingID) { id in
                if let finding = scanner.allFindings.first(where: { $0.id == id }) {
                    FindingDetailView(finding: finding)
                }
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
    @Environment(HistoryStore.self) private var history
    @Environment(PrivacyCheck.self) private var check
    @AppStorage("checkUpDone") private var checkUpStored = ""

    var body: some View {
        let overall = OverallScore.current(scanner: scanner, history: history, check: check, checkUpStored: checkUpStored)
        VStack(alignment: .leading, spacing: 24) {
            LivingMascot(mood: .idle, size: 200)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
            VStack(alignment: .leading, spacing: 12) {
                Brand.eyebrow("hYYa Footprint Inspector")
                AccentRule()
                Text("What do your apps know about you?")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Four quick checks show what apps can learn about you, then help you fix it.")
                    .font(.body)
                    .foregroundStyle(Brand.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 14) {
                Button("Start with check 1") { Task { await scanner.scan() } }
                    .buttonStyle(PrimaryCTAButtonStyle())
                Text("Nothing leaves your device · Open source")
                    .font(.footnote)
                    .foregroundStyle(Brand.textSubtle)
                    .frame(maxWidth: .infinity)
            }
            SectionTitle(title: "Your checks", trailing: "\(overall.doneCount) of \(overall.total)")
            ChecksPanel(overall: overall) { Task { await scanner.scan() } }
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
    @Environment(Scanner.self) private var scanner
    @State private var showingFormula = false
    @State private var fixing = false
    /// The clues you can fix, most points first.
    private var fixes: [Finding] {
        scanner.concerning.filter { FootprintScore.isFixable($0) && FootprintScore.points(for: $0) > 0 }
            .sorted { FootprintScore.points(for: $0) > FootprintScore.points(for: $1) }
    }
    @AppStorage("reviewCardDismissed") private var reviewCardDismissed = false
    @Environment(\.goToTab) private var goToTab
    @Namespace private var zoom

    @Environment(HistoryStore.self) private var history
    @Environment(PrivacyCheck.self) private var check
    @AppStorage("checkUpDone") private var checkUpStored = ""

    var body: some View {
        let score = scanner.score
        let concerning = scanner.concerning
        let overall = OverallScore.current(scanner: scanner, history: history, check: check, checkUpStored: checkUpStored)
        let left = overall.total - overall.doneCount

        // One score for the whole check, then the four checks that make it up.
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                ScoreOrb(value: overall.value ?? score.value, size: 128, tint: tint(overall.level))
                Spacer()
                LivingMascot(mood: concerning.isEmpty ? .happy : .concerned, size: 132)
            }
            .padding(.top, 20)
            VStack(alignment: .leading, spacing: 6) {
                Brand.eyebrow("Your privacy score")
                Text(overall.level?.title ?? "")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Brand.ink)
                AccentRule().padding(.vertical, 4)
                Text(left == 0 ? "All \(overall.total) checks done. Higher is better." :
                        "Based on \(overall.doneCount) of \(overall.total) checks. Do the other \(left) to complete your score.")
                    .font(.body)
                    .foregroundStyle(Brand.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Button("How the score works") { showingFormula = true }
                    .buttonStyle(.plain)
                    .font(.footnote)
                    .foregroundStyle(Brand.textSubtle)
                    .padding(.top, 2)
            }
            ChecksPanel(overall: overall)
        }
        .sheet(isPresented: $showingFormula) { FormulaSheet() }
        .sheet(isPresented: $fixing) { FixWizard(fixes: fixes) { Task { await scanner.scan() } } }

        SectionDivider()

        // Check 1 in detail: the footprint score and its clues.
        VStack(alignment: .leading, spacing: 14) {
            Brand.eyebrow("Check 1 · Footprint")
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
            HStack(spacing: 12) {
                Button("Scan again") { Task { await scanner.scan() } }
                    .buttonStyle(PrimaryCTAButtonStyle())
                ShareCardButton()
            }
        }

        ScoreGuideCard(score: score, fixes: fixes, all: scanner.allFindings) { fixing = true }
            .task { if LaunchOptions.has("-openFix") && !fixes.isEmpty { fixing = true } }


        SectionDivider()

        if let comparison = scanner.comparison {
            ToneCard(tone: .context) { ComparisonCard(comparison: comparison) }
        }

        if !concerning.isEmpty {
            SectionTitle(title: "Worth a look", trailing: "\(concerning.count)")
            Panel {
                ForEach(concerning) { finding in
                    NavigationLink { FindingDetailView(finding: finding).zoomFrom(finding.id, in: zoom) } label: {
                        ClueRow(finding: finding).zoomSource(finding.id, in: zoom)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }

        group(.passive, title: "Seen without asking")
        group(.advanced, title: "Clever tricks")
        group(.permission, title: "Seen once you allow it")

        if scanner.history.snapshots.count >= 2 && !reviewCardDismissed {
            ReviewCard { withAnimation { reviewCardDismissed = true } }
        }

        SectionTitle(title: "Over time")
        Panel {
            NavigationLink { ScoreboardView() } label: {
                RowCard(symbol: "checkmark.seal", title: "Privacy scoreboard", subtitle: "What Apple has fixed, and what's still open")
            }
            .buttonStyle(PressableCardStyle())
            NavigationLink { HistoryView() } label: {
                RowCard(symbol: "chart.line.uptrend.xyaxis", title: "Scan history", subtitle: "Kept only on this device")
            }
            .buttonStyle(PressableCardStyle())
        }

        NextStepCard(step: .sensitive) { goToTab(.sensitive) }
    }

    private func tint(_ level: OverallScore.Level?) -> Color {
        switch level {
        case .good?: Tone.fix.tint
        case .fair?: Brand.sand
        default: Tone.alert.tint
        }
    }

    @ViewBuilder
    private func group(_ group: SignalGroup, title: String) -> some View {
        SectionTitle(title: title)
        Panel {
            ForEach(SignalSection.onThisPlatform.filter { $0.group == group }) { section in
                NavigationLink { SectionView(section: section).zoomFrom(section.id, in: zoom) } label: {
                    CategoryTile(section: section).zoomSource(section.id, in: zoom)
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

private struct FormulaSheet: View {
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
