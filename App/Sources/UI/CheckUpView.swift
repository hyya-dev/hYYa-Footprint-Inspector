// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct CheckUpView: View {
    /// Ticked steps, remembered on this phone only so the user can pick up where they left off.
    @AppStorage("checkUpDone") private var stored = ""

    private var done: Set<String> { Set(stored.split(separator: ",").map(String.init)) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("iPhone never tells one app which other apps can reach your Health data, location or photos. Only Settings knows. This check-up walks you through it, one area at a time.")
                        .font(.subheadline)
                    ProgressView(value: Double(done.count), total: Double(CheckUpGuide.steps.count)) {
                        Text("\(done.count) of \(CheckUpGuide.steps.count) checked")
                            .font(.caption)
                    }
                    .tint(Brand.calm)
                }
                Section {
                    ForEach(CheckUpGuide.steps) { step in
                        NavigationLink {
                            CheckUpStepView(step: step, isDone: binding(for: step.id))
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: done.contains(step.id) ? "checkmark.circle.fill" : step.symbol)
                                    .foregroundStyle(done.contains(step.id) ? Brand.calm : Brand.blue)
                                    .frame(width: 28)
                                Text(step.title)
                            }
                        }
                    }
                }
                if !done.isEmpty {
                    Section {
                        Button("Start over", role: .destructive) { stored = "" }
                    }
                }
            }
            .navigationTitle("Permission check-up")
            .navigationBarTitleDisplayMode(.inline)
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
    @Binding var isDone: Bool

    var body: some View {
        List {
            Section("Why it matters") { Text(step.why) }
            Section("Where to go") {
                Label(step.path, systemImage: "gear")
                    .textSelection(.enabled)
            }
            Section("What to do") {
                ForEach(Array(step.actions.enumerated()), id: \.offset) { index, action in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Brand.blue.opacity(0.15)))
                        Text(action)
                    }
                }
                Button("Open Settings") { SettingsLink.openSettingsHome() }
            }
            Section {
                Toggle("I've checked this", isOn: $isDone)
                    .tint(Brand.calm)
            }
        }
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
