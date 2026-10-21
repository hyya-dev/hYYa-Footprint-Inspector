// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct CheckUpView: View {
    #if os(macOS)
    static let introLine = "macOS never tells one app which other apps can reach your location, contacts or screen. Only System Settings knows, so let's look together."
    #else
    static let introLine = "The system never tells one app which other apps can reach your Health, location or photos. Only Settings knows, so let's look together."
    #endif

    /// Ticked steps, remembered on this phone only so the user can pick up where they left off.
    @AppStorage("checkUpDone") private var stored = ""

    private var done: Set<String> { Set(stored.split(separator: ",").map(String.init)) }

    var body: some View {
        let total = CheckUpGuide.steps.count
        NavigationStack {
            Page {
                HeroCard(eyebrow: "Permission check-up",
                         title: done.count == total ? "All checked!" : "\(done.count) of \(total) checked",
                         subtitle: Self.introLine,
                         mood: done.count == total ? .happy : .idle,
                         mascotSize: 104) {
                    ProgressView(value: Double(done.count), total: Double(total))
                        .tint(Brand.sunflower)
                        .padding(.top, 6)
                        .animation(.spring, value: done.count)
                }

                Panel {
                    ForEach(Array(CheckUpGuide.steps.enumerated()), id: \.element.id) { index, step in
                        NavigationLink {
                            CheckUpStepView(step: step, number: index + 1, isDone: binding(for: step.id))
                        } label: {
                            RowCard(symbol: done.contains(step.id) ? "checkmark" : step.symbol,
                                    title: step.title,
                                    subtitle: step.path,
                                    tileFG: done.contains(step.id) ? .white : Brand.accent,
                                    tileBG: done.contains(step.id) ? Brand.mint : Brand.lilacSoft) {
                                Text("\(index + 1)")
                                    .font(.system(.footnote).weight(.heavy))
                                    .foregroundStyle(Brand.textSubtle)
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
            .inlineTitle()
            .clearNavigationBar()
            .sensoryFeedback(.success, trigger: done.count == total)
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
    let step: CheckUpStep
    var number: Int = 1
    @Binding var isDone: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Page {
            HeroCard(eyebrow: "Step \(number)", title: step.title, subtitle: step.why,
                     mood: isDone ? .happy : .thinking, mascotSize: 96)

            InfoCard(title: "Where to go", symbol: "gearshape.fill") {
                Text(step.path)
                    .font(.system(.body).weight(.semibold))
                    .foregroundStyle(Brand.accent)
                    .textSelection(.enabled)
            }
            InfoCard(title: "What to do", symbol: "list.number") {
                StepList(steps: step.actions)
            }
            #if os(macOS)
            Button("Open in System Settings") {
                if let pane = step.pane { SettingsLink.open(pane: pane) } else { SettingsLink.openSettingsHome() }
            }
            .buttonStyle(GhostButtonStyle())
            .frame(maxWidth: .infinity)
            #else
            Button("Open Settings") { SettingsLink.openSettingsHome() }
                .buttonStyle(GhostButtonStyle())
                .frame(maxWidth: .infinity)
            #endif

            Button(isDone ? "Checked ✓" : "I've checked this") {
                isDone.toggle()
                if isDone { Haptics.success(); dismiss() }
            }
            .buttonStyle(PrimaryCTAButtonStyle(fill: isDone ? Brand.green : Brand.cta,
                                               depthColor: isDone ? Color(hex: 0x0E8A56) : Brand.ctaDepth))
        }
        .navigationTitle(step.title)
        .inlineTitle()
    }
}
