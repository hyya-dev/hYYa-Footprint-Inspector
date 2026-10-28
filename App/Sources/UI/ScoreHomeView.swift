// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// The home page: one privacy score for all four checks, each check's own part, and the way to
/// share it. The score is kept between launches and moves as soon as any check changes
/// (owner, 2026-10-28).
struct ScoreHomeView: View {
    /// Phones only: Settings opens from here, because the tab bar has room for five pages.
    var showsSettingsButton = false
    @Environment(Scanner.self) private var scanner
    @Environment(HistoryStore.self) private var history
    @Environment(PrivacyCheck.self) private var check
    @Environment(\.goToTab) private var goToTab
    @AppStorage("checkUpDone") private var checkUpStored = ""
    @AppStorage(TrackerPlaces.storageKey) private var trackerStored = ""
    @State private var showingFormula = false
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var short: Bool { verticalSizeClass == .compact }
    #else
    private let short = false
    #endif
    @State private var showingSettings = LaunchOptions.value(after: "-startTab") == "settings"

    var body: some View {
        let overall = OverallScore.current(scanner: scanner, history: history, check: check,
                                           checkUpStored: checkUpStored, trackerStored: trackerStored)
        NavigationStack {
            Page {
                if showsSettingsButton {
                    HStack {
                        Spacer()
                        Button { showingSettings = true } label: { Label("Settings", systemImage: "gearshape") }
                            .buttonStyle(GhostButtonStyle())
                    }
                }
                if let value = overall.value {
                    scoreHeader(overall, value: value)
                } else {
                    welcome
                }
                SectionTitle(title: "Your checks", trailing: "\(overall.doneCount) of \(overall.total)")
                ChecksPanel(overall: overall)
                if overall.value != nil {
                    ToneCard(tone: .context, title: "Stay on top of it", symbol: "calendar.badge.clock") {
                        Text("A restart once a week clears some kinds of spyware and gives apps a new restart time. I can remind you.")
                            .font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                        WeeklyReminderToggle()
                    }
                }
            }
            .hiddenNavigationBar()
            .sheet(isPresented: $showingFormula) { FormulaSheet() }
            #if os(iOS)
            .sheet(isPresented: $showingSettings) { SettingsView(onClose: { showingSettings = false }) }
            #endif
        }
    }

    /// Before any check: what the app does and the first step.
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Sideways on a phone the mascot shrinks, so the first step stays on screen.
            LivingMascot(mood: .idle, size: short ? 90 : 200)
                .frame(maxWidth: .infinity)
                .padding(.top, short ? 0 : 12)
            VStack(alignment: .leading, spacing: 12) {
                Brand.eyebrow("hYYa Footprint Inspector")
                AccentRule()
                Text("What do your apps know about you?")
                    .scaledFont(34, weight: .bold, relativeTo: .largeTitle)
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Four quick checks show what apps can learn about you, then help you fix it.")
                    .font(.body)
                    .foregroundStyle(Brand.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 14) {
                Button("Start with check 1") {
                    goToTab(.footprint)
                    Task { await scanner.scan() }
                }
                .buttonStyle(PrimaryCTAButtonStyle())
                Text("Nothing leaves your device · Open source")
                    .font(.footnote)
                    .foregroundStyle(Brand.textSubtle)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func scoreHeader(_ overall: OverallScore, value: Int) -> some View {
        let left = overall.total - overall.doneCount
        return VStack(alignment: .leading, spacing: 18) {
            // Side by side when they fit; stacked at the largest text sizes, where the ring grows.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center) {
                    ScoreOrb(value: value, size: 128, tint: Self.tint(overall.level))
                    Spacer()
                    LivingMascot(mood: overall.level == .good ? .happy : .concerned, size: 132)
                }
                VStack(alignment: .leading, spacing: 12) {
                    LivingMascot(mood: overall.level == .good ? .happy : .concerned, size: 104)
                    ScoreOrb(value: value, size: 128, tint: Self.tint(overall.level))
                }
            }
            .padding(.top, 12)
            VStack(alignment: .leading, spacing: 6) {
                Brand.eyebrow("Your privacy score")
                Text(overall.level?.title ?? "")
                    .scaledFont(30, weight: .bold, relativeTo: .largeTitle)
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
            OverallShareButton(overall: overall)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    static func tint(_ level: OverallScore.Level?) -> Color {
        switch level {
        case .good?: Tone.fix.tint
        case .fair?: Brand.sand
        default: Tone.alert.tint
        }
    }
}
