// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Charts
import SwiftUI

// MARK: - Since last scan (before / after)

struct ComparisonCard: View {
    let comparison: ScanComparison

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Space.sm) {
            HStack {
                Brand.eyebrow("Since your last scan")
                Spacer()
                Text(comparison.previous.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(Brand.textSubtle)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(comparison.previous.score)")
                    .foregroundStyle(Brand.textSubtle)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Brand.textSubtle)
                Text("\(comparison.current.score)")
                    .foregroundStyle(Brand.textPrimary)
                deltaLabel
            }
            .font(.title2.weight(.bold).monospacedDigit())

            if comparison.osChanged {
                Label("You updated the system since then.", systemImage: "arrow.down.app")
                    .font(.subheadline)
                    .foregroundStyle(Brand.accent)
            }
            if !comparison.resolved.isEmpty {
                changeList("No longer worth a look", ids: comparison.resolved, symbol: "checkmark.circle.fill", tint: Brand.calm)
            }
            if !comparison.newConcerns.isEmpty {
                changeList("Newly worth a look", ids: comparison.newConcerns, symbol: "exclamationmark.circle.fill", tint: Brand.concern)
            }
            let others = comparison.changed.filter { !comparison.resolved.contains($0) && !comparison.newConcerns.contains($0) }
            if !others.isEmpty {
                Text("\(others.count) other value\(others.count == 1 ? "" : "s") changed, such as \(Self.titles(others.prefix(3)).joined(separator: ", ")).")
                    .font(.footnote)
                    .foregroundStyle(Brand.textMuted)
            }
            if comparison.resolved.isEmpty && comparison.newConcerns.isEmpty && others.isEmpty {
                Text("Nothing changed.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var deltaLabel: some View {
        let d = comparison.scoreDelta
        if d != 0 {
            Text(d > 0 ? "+\(d)" : "\(d)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(d > 0 ? Brand.calm : Brand.concern)
        }
    }

    private func changeList(_ title: String, ids: [String], symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            ForEach(Self.titles(ids), id: \.self) { name in
                Label(name, systemImage: symbol)
                    .font(.subheadline)
                    .foregroundStyle(tint)
            }
        }
    }

    static func titles<S: Sequence>(_ ids: S) -> [String] where S.Element == String {
        ids.map { SignalCatalogue.definition($0)?.title ?? $0 }
    }
}

// MARK: - History

struct HistoryView: View {
    @Environment(HistoryStore.self) private var history

    var body: some View {
        List {
                Section {
                    MascotSays(line: history.snapshots.count < 2 ? "Scan a few times and I’ll draw your progress here." : "Here’s how your footprint has changed.", mood: .thinking, size: 80)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            if history.snapshots.count >= 2 {
                Section {
                    Chart(history.snapshots) { snapshot in
                        LineMark(x: .value("Date", snapshot.date), y: .value("Score", snapshot.score))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(Brand.accent)
                        PointMark(x: .value("Date", snapshot.date), y: .value("Score", snapshot.score))
                            .foregroundStyle(Brand.accent)
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 180)
                    .padding(.vertical, 6)
                    .accessibilityLabel("Score over time")
                } footer: {
                    Text("Higher is a lighter footprint.")
                }
            }
            Section {
                if history.snapshots.isEmpty {
                    Text("Your scans will appear here.")
                        .foregroundStyle(Brand.textMuted)
                }
                ForEach(history.snapshots.reversed()) { snapshot in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(snapshot.date.formatted(date: .abbreviated, time: .shortened))
                            Text("\(snapshot.concerningIDs.count) worth a look · \(Self.shortOS(snapshot.osVersion))")
                                .font(.caption)
                                .foregroundStyle(Brand.textSubtle)
                        }
                        Spacer()
                        Text("\(snapshot.score)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(Brand.accent)
                    }
                }
            } footer: {
                Text("Kept only on this device, not in backups. Values themselves are never saved: only the score, what was worth a look, and a scrambled marker to spot changes.")
            }
        }
        .brandListBackground()
        .navigationTitle("History")
    }

    static func shortOS(_ full: String) -> String {
        full.replacingOccurrences(of: "Version ", with: "\(System.name) ").components(separatedBy: " (").first ?? full
    }
}

// MARK: - iOS scoreboard

struct ScoreboardView: View {
    @Environment(HistoryStore.self) private var history

    private var all: [SignalDefinition] { Array(SignalCatalogue.all.values).sorted { $0.title < $1.title } }
    private var closed: [(SignalDefinition, String)] {
        all.compactMap { def in if case .changed(let note) = def.status { (def, note) } else { nil } }
    }
    private var open: [SignalDefinition] {
        all.filter { if case .stillOpen = $0.status { true } else { false } }
    }

    var body: some View {
        List {
                Section {
                    MascotSays(line: "I keep score of what Apple has fixed. Updating the system is the easiest privacy win.", mood: .happy, size: 80)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("You're on \(System.name) \(UIDevice.current.systemVersion)")
                        .font(.headline)
                    Text(Self.majorVersion < 27
                         ? "Updating to \(System.name) 27 brings the fixes below."
                         : "You have Apple's latest fixes.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textMuted)
                }
                .padding(.vertical, 4)
            }
            Section {
                ForEach(closed, id: \.0.id) { def, note in
                    VStack(alignment: .leading, spacing: 3) {
                        Label(def.title, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Brand.calm)
                        Text(note).font(.footnote).foregroundStyle(Brand.textMuted)
                    }
                }
            } header: {
                Text("Closed or limited by Apple")
            }
            Section {
                ForEach(open) { def in
                    VStack(alignment: .leading, spacing: 3) {
                        Label(def.title, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(Brand.concern)
                        Text(def.reveals).font(.footnote).foregroundStyle(Brand.textMuted)
                    }
                }
            } header: {
                Text("Still open in \(System.name) 27")
            } footer: {
                Text("These need a change from Apple. Nothing in Settings switches them off.")
            }
            if let change = osChange {
                Section("After your last system update") {
                    Text("Your score went from \(change.previous.score) to \(change.current.score) across the update to \(HistoryView.shortOS(change.current.osVersion)).")
                    if !change.resolved.isEmpty {
                        Text("No longer worth a look: \(ComparisonCard.titles(change.resolved).joined(separator: ", ")).")
                            .foregroundStyle(Brand.calm)
                    }
                }
            }
        }
        .brandListBackground()
        .navigationTitle("Privacy scoreboard")
    }

    private static var majorVersion: Int {
        Int(UIDevice.current.systemVersion.split(separator: ".").first ?? "0") ?? 0
    }

    /// The most recent pair of saved scans either side of an iOS update.
    private var osChange: ScanComparison? {
        let s = history.snapshots
        guard s.count >= 2 else { return nil }
        for i in stride(from: s.count - 1, to: 0, by: -1) where s[i].osVersion != s[i - 1].osVersion {
            return ScanComparison(previous: s[i - 1], current: s[i])
        }
        return nil
    }
}
