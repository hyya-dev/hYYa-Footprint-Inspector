// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// The installed-app check. Safety rules (docs/SENSITIVE-APP-CATALOGUE.md §5):
/// - every category starts off and is checked only when the user taps Check
/// - results sit behind a tap and a blur, and vanish when the app leaves the screen
/// - results are never stored; only the category choices are remembered
struct SensitiveView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("sensitiveCategories") private var storedChoice = ""
    @State private var results: [String: [SensitiveApp]]? = nil
    @State private var revealed = false
    @State private var pendingCaution: [SensitiveCategory] = []

    private var chosen: Set<String> {
        Set(storedChoice.split(separator: ",").map(String.init))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("No app can see the full list of what's installed on your iPhone. But any app can ask about specific apps, one by one, and iOS answers. Choose which kinds of apps to check, and we'll show you what any app could find.")
                        .font(.subheadline)
                }

                Section {
                    ForEach(SensitiveCatalogue.categories) { category in
                        Toggle(isOn: binding(for: category.id)) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.title)
                                    Text(category.apps.map(\.name).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: category.symbol).foregroundStyle(Brand.blue)
                            }
                        }
                    }
                } header: {
                    Text("Kinds of apps")
                } footer: {
                    Text("iOS limits every app to asking about 25 apps, so we picked the ones that say the most about a person.")
                }

                Section {
                    Button {
                        startCheck()
                    } label: {
                        Text("Check").bold().frame(maxWidth: .infinity)
                    }
                    .disabled(chosen.isEmpty)
                }

                if let results { resultSection(results) }
            }
            .brandListBackground()
            .navigationTitle("Sensitive apps")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Before you check",
                   isPresented: Binding(get: { !pendingCaution.isEmpty }, set: { if !$0 { pendingCaution = [] } })) {
                Button("Check") { pendingCaution = []; runCheck() }
                Button("Cancel", role: .cancel) { pendingCaution = [] }
            } message: {
                Text(SensitiveCatalogue.riskyCountriesCaution)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { results = nil; revealed = false }
            }
        }
    }

    @ViewBuilder
    private func resultSection(_ results: [String: [SensitiveApp]]) -> some View {
        let categories = SensitiveCatalogue.categories.filter { results[$0.id] != nil }
        let foundCount = results.values.reduce(0) { $0 + $1.count }
        Section {
            if foundCount == 0 {
                Label("None of these apps answered. An app checking the same list would find nothing.", systemImage: "checkmark.shield")
                    .foregroundStyle(Brand.calm)
            } else {
                ZStack {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(categories) { category in
                            if let apps = results[category.id], !apps.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(category.title).font(.headline)
                                    Text(apps.map(\.name).joined(separator: ", "))
                                    Text(category.inference)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .blur(radius: revealed ? 0 : 12)
                    .accessibilityHidden(!revealed)

                    if !revealed {
                        Button {
                            revealed = true
                        } label: {
                            Label("Tap to reveal", systemImage: "eye")
                                .padding(.horizontal, 14).padding(.vertical, 8)
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding(.vertical, 6)
            }
        } header: {
            Text(foundCount == 0 ? "Result" : "Found \(foundCount)")
        } footer: {
            Text("Hidden again when you leave the app. Never saved. \"Found\" means an app that answers to that name is installed; a similar app can sometimes answer for it.")
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding {
            chosen.contains(id)
        } set: { on in
            var set = chosen
            if on { set.insert(id) } else { set.remove(id) }
            storedChoice = set.sorted().joined(separator: ",")
            results = nil
            revealed = false
        }
    }

    private func startCheck() {
        let cautious = SensitiveCatalogue.categories.filter { chosen.contains($0.id) && $0.caution != nil }
        if cautious.isEmpty { runCheck() } else { pendingCaution = cautious }
    }

    private func runCheck() {
        revealed = false
        results = SensitiveCatalogue.scan(chosen)
    }
}
