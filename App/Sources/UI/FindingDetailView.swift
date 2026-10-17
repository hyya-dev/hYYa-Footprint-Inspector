// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import UIKit

struct FindingDetailView: View {
    @Environment(Scanner.self) private var scanner
    let finding: Finding
    @State private var cleared = false

    private var def: SignalDefinition { finding.definition }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        SeverityDot(severity: finding.severity)
                        Text(finding.severity.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.color(for: finding.severity))
                    }
                    Text(finding.reading.value)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .textSelection(.enabled)
                    if let note = finding.reading.note {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(finding.reading.raisedSeverity == .high ? Brand.amber : .secondary)
                    }
                    StatusBadge(status: def.status)
                }
                .padding(.vertical, 4)
            } header: {
                Text("On this iPhone")
            }

            if !finding.reading.items.isEmpty {
                Section("Details") {
                    ForEach(Array(finding.reading.items.enumerated()), id: \.offset) { _, item in
                        Text(item)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }

            Section("What an app learns") {
                Text(def.reveals)
            }
            Section("Why iPhone allows it") {
                Text(def.why)
            }
            Section("How long it lasts") {
                Label(def.persistence.label, systemImage: "clock")
            }

            Section {
                Text(def.fix.summary)
                ForEach(Array(def.fix.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Brand.blue.opacity(0.15)))
                        Text(step)
                    }
                }
                fixActions
            } header: {
                Label(def.fix.level.label, systemImage: def.fix.level == .onlyApple ? "applelogo" : "wrench.and.screwdriver")
            }
        }
        .navigationTitle(def.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var fixActions: some View {
        if def.id == "clip-kinds" {
            Button(cleared ? "Clipboard cleared" : "Clear the clipboard now") {
                UIPasteboard.general.items = []
                cleared = true
                Task { await scanner.scan() }
            }
            .disabled(cleared)
        }
        if def.fix.level == .guided || def.fix.level == .openSettings {
            Button("Open Settings") { SettingsLink.openSettingsHome() }
        }
    }
}
