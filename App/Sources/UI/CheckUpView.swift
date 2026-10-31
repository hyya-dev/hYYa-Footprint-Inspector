// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct CheckUpView: View {
    #if os(macOS)
    static let introLine = "macOS never tells one app which other apps can reach your location, contacts or screen. Only System Settings knows, so let's look together."
    #else
    static let introLine = "Keep spying apps out, then see which apps can reach your Health, location or photos. Only Settings knows, so let's look together, one area at a time."
    #endif

    /// Ticked steps, remembered on this phone only so the user can pick up where they left off.
    @CheckStored(\.checkUpDone) private var stored
    /// The open area, saved on this device so it's still open after the person goes to Settings,
    /// even if iOS quit the app meanwhile (owner, 2026-10-28).
    @AppStorage("nav.checkup") private var openStep = ""

    private var done: Set<String> { Set(stored.split(separator: ",").map(String.init)) }

    var body: some View {
        let total = CheckUpGuide.steps.count
        ListDetailStack {
            Page {
                HeroCard(eyebrow: "Check-up",
                         title: done.count == total ? "All checked!" : "\(done.count) of \(total) checked",
                         subtitle: Self.introLine,
                         mood: done.count == total ? .happy : .idle,
                         mascotSize: 104) {
                    ProgressView(value: Double(done.count), total: Double(total))
                        .tint(Tone.fix.tint)
                        .padding(.top, 6)
                        .animation(.spring, value: done.count)
                }

                Panel {
                    ForEach(Array(CheckUpGuide.steps.enumerated()), id: \.element.id) { index, step in
                        Button { openStep = step.id } label: {
                            RowCard(symbol: done.contains(step.id) ? "checkmark" : step.symbol,
                                    title: step.title,
                                    subtitle: step.path,
                                    tileFG: done.contains(step.id) ? .white : Brand.accent,
                                    tileBG: done.contains(step.id) ? Brand.mint : Brand.lilacSoft) {
                                Image(systemName: done.contains(step.id) ? "checkmark.circle.fill" : "chevron.right")
                                    .foregroundStyle(done.contains(step.id) ? Tone.fix.tint : Brand.textSubtle)
                            }
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }

                if !done.isEmpty {
                    Button("Start over") { stored = "" }
                        .buttonStyle(GhostButtonStyle(tint: Brand.concern))
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Check-up")
            // The page's own heading names it; no second title bar above it, as on Score,
            // Footprint and Settings.
            .hiddenNavigationBar()
            .sensoryFeedback(.success, trigger: done.count == total)
            .navigationDestination(item: Binding(get: { openStep.isEmpty ? nil : openStep }, set: { openStep = $0 ?? "" })) { id in
                if let i = CheckUpGuide.steps.firstIndex(where: { $0.id == id }) {
                    CheckUpStepView(step: CheckUpGuide.steps[i], number: i + 1, isDone: binding(for: id))
                }
            }
            // A restart in the last week is the restart step done: tick it without asking.
            .task { if CheckUpStepView.restartedRecently { binding(for: "restart").wrappedValue = true } }
        } placeholder: {
            DetailPlaceholder(line: "Pick an area to see where to go and what to do.")
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding {
            done.contains(id)
        } set: { on in
            var set = done
            if on { set.insert(id) } else { set.remove(id) }
            stored = set.sorted().joined(separator: ",")
        }
    }
}

struct CheckUpStepView: View {
    /// The restart step exists on phones only; a Mac's restart is in its Footprint findings.
    static var restartedRecently: Bool {
        guard !LaunchOptions.has("-sampleData"), CheckUpGuide.steps.contains(where: { $0.id == "restart" }), let boot = Sysctl.bootTime() else { return false }
        return RecentRestart.isRecent(boot: boot)
    }

    /// "Settings › Privacy & Security › Location Services" → "Location Services".
    static func searchTerm(_ path: String) -> String? {
        guard path.hasPrefix("Settings ›") else { return nil }
        let last = path.components(separatedBy: "›").last?.trimmingCharacters(in: .whitespaces) ?? ""
        let term = last.components(separatedBy: ", then").first?.trimmingCharacters(in: .whitespaces) ?? last
        return term.isEmpty || term.hasPrefix("[") ? nil : term
    }

    let step: CheckUpStep
    var number: Int = 1
    @Binding var isDone: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.goToTab) private var goToTab

    var body: some View {
        Page {
            HeroCard(eyebrow: "Check-up", title: step.title, subtitle: step.why,
                     mood: isDone ? .happy : .thinking, mascotSize: 96)

            ToneCard(tone: .context, title: "Where to go", symbol: "gearshape") {
                Text(step.path)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Tone.context.tint)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                #if os(iOS)
                // No app can open another Settings page directly, so give the quickest way there.
                if let term = Self.searchTerm(step.path) {
                    Label("Quickest: open Settings and type \"\(term)\" in its search bar.", systemImage: "magnifyingglass")
                        .font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                }
                #endif
            }
            if step.id == "restart", Self.restartedRecently, let boot = Sysctl.bootTime() {
                ToneCard(tone: .fix, title: "Already done", symbol: "checkmark.seal") {
                    Text("This device last restarted \(boot.formatted(.relative(presentation: .named))). That counts, so I've ticked it for you.")
                        .font(.body).foregroundStyle(Brand.ink).fixedSize(horizontal: false, vertical: true)
                }
            }
            ToneCard(tone: .fix, title: "What to do", symbol: "checklist") {
                StepList(steps: step.actions, tint: Tone.fix.tint)
                if step.id == "restart" { WeeklyReminderToggle() }
            }
            #if os(iOS)
            if step.id == "privacy-report" {
                NextStepCard(step: .tracker) { goToTab(.tracker) }
            }
            #endif
            #if os(macOS)
            if let app = step.app {
                // Not a setting: open the app itself.
                Button(app.title) { SettingsLink.openApp(bundleID: app.bundleID) }
                    .buttonStyle(GhostButtonStyle())
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 12) {
                    Button("Open in System Settings") {
                        if let pane = step.pane { SettingsLink.open(pane: pane) } else { SettingsLink.openSettingsHome() }
                    }
                    .buttonStyle(GhostButtonStyle())
                    if let second = step.secondPane {
                        Button(second.title) { SettingsLink.open(pane: second.pane) }
                            .buttonStyle(GhostButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity)
            }
            #else
            // Restarting and the Passwords app aren't in Settings, so there's no Settings button.
            if step.id != "restart" && step.id != "passwords" {
                Button("Open Settings") { SettingsLink.openSettingsHome() }
                    .buttonStyle(GhostButtonStyle())
                    .frame(maxWidth: .infinity)
            }
            #endif

            Button(isDone ? "Checked ✓" : "I've checked this") {
                isDone.toggle()
                if isDone { Haptics.success(); dismiss() }
            }
            .buttonStyle(PrimaryCTAButtonStyle(fill: isDone ? Brand.green : Brand.cta,
                                               depthColor: isDone ? Color(hex: 0x0E8A56) : Brand.ctaDepth))
        }
        .navigationTitle("")
        .inlineTitle()
    }
}
