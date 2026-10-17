// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct SectionView: View {
    @Environment(Scanner.self) private var scanner
    let section: SignalSection

    private var kind: PermissionKind? {
        PermissionKind.allCases.first { $0.section == section }
    }

    var body: some View {
        let findings = scanner.findings(in: section)
        List {
            if let kind {
                permissionHeader(kind, hasFindings: !findings.isEmpty)
            }
            if !findings.isEmpty {
                Section {
                    ForEach(findings) { finding in
                        NavigationLink { FindingDetailView(finding: finding) } label: {
                            FindingRow(finding: finding)
                        }
                    }
                }
            } else if kind == nil {
                Section {
                    Text("Nothing was read here on this device.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("What an app with this permission gets") {
                    ForEach(SignalCatalogue.definitions(in: section)) { def in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                SeverityDot(severity: def.severity)
                                Text(def.title).font(.headline)
                            }
                            Text(def.reveals)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .brandListBackground()
        .navigationTitle(section.title)
    }

    @ViewBuilder
    private func permissionHeader(_ kind: PermissionKind, hasFindings: Bool) -> some View {
        let state = scanner.permissionStates[kind] ?? .notAsked
        let loading = scanner.loadingPermissions.contains(kind)
        Section {
            switch state {
            case .granted, .limited:
                if !hasFindings {
                    Button("Show me") { Task { await scanner.reveal(kind) } }
                        .disabled(loading)
                }
                if state == .limited {
                    Text("You gave limited access, so this shows only what you shared. That's the safer choice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            case .notAsked:
                Text("Any app you allow \(section.title) can see the things below. Tap Show me and we'll ask iOS for the same permission, then show you exactly what an app would get.")
                    .font(.subheadline)
                Button {
                    Task { await scanner.reveal(kind) }
                } label: {
                    if loading { ProgressView() } else { Text("Show me").bold() }
                }
                .disabled(loading)
            case .denied:
                Text("You said no to this permission, so we can't show what an app would get. That's a good sign: apps you said no to can't see it either.")
                    .font(.subheadline)
                Button("Change in Settings") { SettingsLink.openOwnPage() }
            case .unavailable:
                Text("This isn't available on this device.")
                    .foregroundStyle(.secondary)
            }
            if loading && state != .notAsked { ProgressView("Reading…") }
        } footer: {
            Text("Nothing read here is saved or sent anywhere.")
        }
    }
}
