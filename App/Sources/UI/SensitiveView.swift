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
    @State private var checks = 0

    private var chosen: Set<String> {
        Set(storedChoice.split(separator: ",").map(String.init))
    }

    private var foundCount: Int { results?.values.reduce(0) { $0 + $1.count } ?? 0 }

    var body: some View {
        NavigationStack {
            Page {
                HeroCard(eyebrow: "Sensitive apps",
                         title: "Which apps give you away?",
                         subtitle: "Apps can't list what you've installed, but they can ask about specific apps, one by one. Pick what to check.",
                         mood: heroMood,
                         mascotSize: 104)

                if let results {
                    resultCard(results)
                    if revealed { adviceCards(results) }
                }

                SectionTitle(title: "Kinds of apps", trailing: "\(chosen.count) on")
                Panel {
                    ForEach(SensitiveCatalogue.categories) { category in
                        CategoryToggle(category: category, isOn: chosen.contains(category.id)) { toggle(category.id) }
                    }
                }
                Text("iOS lets each app ask about 25 apps at most, so I picked the ones that say the most about a person.")
                    .font(.system(.footnote))
                    .foregroundStyle(Brand.textSubtle)
                    .padding(.horizontal, 4)

                Button(chosen.isEmpty ? "Pick at least one kind" : "Check \(chosen.count) kind\(chosen.count == 1 ? "" : "s")") { startCheck() }
                    .buttonStyle(PrimaryCTAButtonStyle())
                    .disabled(chosen.isEmpty)
            }
            .navigationTitle("Sensitive apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
            .sensoryFeedback(trigger: checks) { _, _ in foundCount > 0 ? .warning : .success }
        }
    }

    private var heroMood: LivingMascot.Mood {
        guard results != nil else { return .idle }
        return foundCount > 0 ? .concerned : .happy
    }

    private func resultCard(_ results: [String: [SensitiveApp]]) -> some View {
        let categories = SensitiveCatalogue.categories.filter { !(results[$0.id] ?? []).isEmpty }
        return VStack(alignment: .leading, spacing: 12) {
            if foundCount == 0 {
                MascotSays(line: "None of these apps answered. Any app asking the same would find nothing.", mood: .happy, size: 76)
            } else {
                Text("Found \(foundCount)")
                    .font(Brand.display(24))
                    .foregroundStyle(Brand.textPrimary)
                ZStack {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(categories) { category in
                            HStack(alignment: .top, spacing: 12) {
                                IconTile(symbol: category.symbol, fg: Brand.concern, bg: Brand.sunflowerSoft, size: 40)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(category.title).font(.system(.headline))
                                    Text((results[category.id] ?? []).map(\.name).joined(separator: ", "))
                                        .font(.system(.body).weight(.semibold))
                                        .foregroundStyle(Brand.accent)
                                    Text(category.inference)
                                        .font(.system(.footnote))
                                        .foregroundStyle(Brand.textMuted)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .blur(radius: revealed ? 0 : 14)
                    .accessibilityHidden(!revealed)
                    if !revealed {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { revealed = true }
                            Haptics.soft()
                        } label: {
                            Label("Tap to reveal", systemImage: "eye.fill")
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                }
                Text("Hidden again when you leave the app. Never saved. A similar app can sometimes answer for the one named.")
                    .font(.system(.caption))
                    .foregroundStyle(Brand.textSubtle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandCard(padding: 18)
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }

    @ViewBuilder
    private func adviceCards(_ results: [String: [SensitiveApp]]) -> some View {
        let found = SensitiveCatalogue.categories.filter { !(results[$0.id] ?? []).isEmpty }
        if !found.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("What you can do")
                    .font(.headline)
                    .foregroundStyle(Brand.ink)
                Text("Any app on this phone could find the same, without asking. No setting stops it. What helps is fewer revealing apps installed:")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textMuted)
                StepList(steps: [
                    "Delete apps you no longer use. Your accounts usually stay, so you can reinstall later.",
                    "Use the website instead of the app where you can. Websites can't be detected this way.",
                    "Hiding an app or moving it off your Home Screen doesn't help: it's still installed.",
                ])
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.surface))

            ForEach(found) { category in
                InfoCard(title: category.title, symbol: category.symbol) {
                    ForEach(category.advice, id: \.self) { line in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.mint)
                            Text(line).font(.system(.subheadline))
                        }
                    }
                }
                .scrollIn3D()
            }
        }
    }

    private func toggle(_ id: String) {
        var set = chosen
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        storedChoice = set.sorted().joined(separator: ",")
        results = nil
        revealed = false
    }

    private func startCheck() {
        let cautious = SensitiveCatalogue.categories.filter { chosen.contains($0.id) && $0.caution != nil }
        if cautious.isEmpty { runCheck() } else { pendingCaution = cautious }
    }

    private func runCheck() {
        revealed = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            results = SensitiveCatalogue.scan(chosen)
        }
        checks += 1
    }
}

private struct CategoryToggle: View {
    let category: SensitiveCategory
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RowCard(symbol: category.symbol, title: category.title,
                    subtitle: category.apps.map(\.name).joined(separator: ", "),
                    tileFG: isOn ? Brand.ink : Brand.textSubtle) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? Brand.ink : Brand.textSubtle)
            }
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityLabel("\(category.title). \(category.apps.map(\.name).joined(separator: ", "))")
    }
}
