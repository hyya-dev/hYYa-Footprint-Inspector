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
                         subtitle: "Any app can ask whether certain apps are installed, one by one, without asking you. Pick the kinds to check.",
                         mood: heroMood,
                         mascotSize: 104)

                if let results { resultCard(results) }

                SectionTitle(title: "Kinds of apps", trailing: "\(chosen.count) on")
                Panel {
                    ForEach(SensitiveCatalogue.categories) { category in
                        CategoryToggle(category: category, isOn: chosen.contains(category.id)) { toggle(category.id) }
                    }
                }
                Text("The system lets each app ask about 25 apps at most, so I picked the ones that say the most about a person.")
                    .font(.system(.footnote))
                    .foregroundStyle(Brand.textSubtle)
                    .padding(.horizontal, 4)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.fill").foregroundStyle(Brand.sand)
                    Text("Runs only on this device. The result stays hidden until you tap it, and is gone when you leave. Nothing is saved or sent.")
                        .font(.footnote)
                        .foregroundStyle(Brand.textSubtle)
                }
                .padding(.horizontal, 4)

                Button(chosen.isEmpty ? "Pick at least one kind" : "Check \(chosen.count) kind\(chosen.count == 1 ? "" : "s")") { runCheck() }
                    .buttonStyle(PrimaryCTAButtonStyle())
                    .disabled(chosen.isEmpty)
            }
            .navigationTitle("Sensitive apps")
            .inlineTitle()
            .clearNavigationBar()
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
        let found: [(SensitiveCategory, SensitiveApp)] = SensitiveCatalogue.categories.flatMap { category in
            (results[category.id] ?? []).map { (category, $0) }
        }
        return VStack(alignment: .leading, spacing: 12) {
            if found.isEmpty {
                MascotSays(line: "None of these apps answered. Any app asking the same would find nothing.", mood: .happy, size: 76)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .brandCard(padding: 18)
            } else {
                Text(found.count == 1 ? "1 app gives you away" : "\(found.count) apps give you away")
                    .font(Brand.display(24))
                    .foregroundStyle(Brand.textPrimary)
                ZStack {
                    VStack(spacing: 12) {
                        ForEach(found, id: \.1.id) { category, app in
                            FoundAppCard(category: category, app: app)
                        }
                    }
                    .blur(radius: revealed ? 0 : 14)
                    .accessibilityHidden(!revealed)
                    .allowsHitTesting(revealed)
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
                Text("Rarely, a different app answers to the same name.")
                    .font(.system(.caption))
                    .foregroundStyle(Brand.textSubtle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }

    private func toggle(_ id: String) {
        var set = chosen
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        storedChoice = set.sorted().joined(separator: ",")
        results = nil
        revealed = false
    }

    private func runCheck() {
        revealed = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            results = SensitiveCatalogue.scan(chosen)
        }
        checks += 1
    }
}

/// One app that answered: what any app learns from it, then what to do.
private struct FoundAppCard: View {
    let category: SensitiveCategory
    let app: SensitiveApp

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Pill(text: "Worth a look", symbol: "exclamationmark.circle.fill", fg: Brand.concern, bg: Brand.sunflowerSoft)
            Text("Any app can see you have \(app.name)")
                .font(.headline)
                .foregroundStyle(Brand.ink)
            Text([category.tells, category.risk].compactMap { $0 }.joined(separator: " "))
                .font(.subheadline)
                .foregroundStyle(Brand.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            Text(Brand.brandUppercased("What to do"))
                .font(.caption.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(Brand.sand)
                .padding(.top, 4)
            StepList(steps: category.steps + [SensitiveCatalogue.deleteStep])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandCard(padding: 16)
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
