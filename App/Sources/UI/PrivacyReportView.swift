// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

/// "What your apps actually did": the person's own App Privacy Report, opened from Files and read
/// on the device. Kept only while this screen is open, never saved or sent.
struct PrivacyReportView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var report: PrivacyReport?
    @State private var importing = false
    @State private var problem: String?
    @State private var opened = 0

    private static let types: [UTType] = [UTType(filenameExtension: "ndjson") ?? .data, .json, .plainText, .data]

    var body: some View {
        Page {
            HeroCard(eyebrow: "What your apps actually did",
                     title: report == nil ? "See what apps really used" : "Here's what they did",
                     subtitle: "Your device keeps a 7-day record of which apps used your private data and which sites they contacted. Open it here to read it plainly.",
                     mood: report == nil ? .thinking : (report!.trackerSites > 0 ? .concerned : .happy),
                     mascotSize: 96)

            if let report { results(report) } else { howTo }

            if let problem {
                ToneCard(tone: .alert, title: "Couldn't read that file", symbol: "exclamationmark.triangle") {
                    Text(problem).font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(report == nil ? "Open my report" : "Open a newer report") { importing = true }
                .buttonStyle(PrimaryCTAButtonStyle())

            Label {
                Text("Read only on this device. Nothing is saved or sent, and it's cleared when you leave.")
                    .fixedSize(horizontal: false, vertical: true)
            } icon: { Image(systemName: "lock.fill").foregroundStyle(Brand.sand) }
            .font(.footnote)
            .foregroundStyle(Brand.textSubtle)
        }
        .navigationTitle("What apps did")
        .inlineTitle()
        .fileImporter(isPresented: $importing, allowedContentTypes: Self.types) { result in load(result) }
        .onChange(of: scenePhase) { _, phase in if phase == .background { report = nil } }
        .task { if CommandLine.arguments.contains("-sampleData") && report == nil { report = .sample } }
        .sensoryFeedback(trigger: opened) { _, _ in (report?.trackerSites ?? 0) > 0 ? .warning : .success }
    }

    private var howTo: some View {
        ToneCard(tone: .explain, title: "Get your report", symbol: "doc.text.magnifyingglass") {
            StepList(steps: [
                "Open Settings › Privacy & Security › App Privacy Report. If it's off, turn it on and come back in a few days.",
                "Scroll to the bottom and tap Save App Activity, then Save to Files.",
                "Come back here and tap Open my report.",
            ], tint: Tone.explain.tint)
            Button("Open Settings") { SettingsLink.openSettingsHome() }
                .buttonStyle(GhostButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func results(_ r: PrivacyReport) -> some View {
        ToneCard(tone: r.trackerSites > 0 ? .alert : .context, title: "In this report", symbol: "chart.bar.doc.horizontal") {
            if let from = r.from, let to = r.to {
                Text("\(from.formatted(date: .abbreviated, time: .omitted)) to \(to.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote).foregroundStyle(Brand.textSubtle)
            }
            FlowRow {
                ToneBadge(text: "\(r.appsUsingData) used private data", symbol: "lock.open", tone: .alert)
                ToneBadge(text: "\(r.appsContactingSites) contacted sites", symbol: "network", tone: .context)
                ToneBadge(text: "\(r.trackerSites) tracking companies", symbol: "eye.trianglebadge.exclamationmark", tone: r.trackerSites > 0 ? .alert : .fix)
            }
        }
        SectionTitle(title: "App by app", trailing: "\(r.apps.count)")
        ForEach(r.apps) { app in AppActivityCard(app: app) }
        ToneCard(tone: .fix, title: "Take access back", symbol: "wrench.and.screwdriver") {
            StepList(steps: [
                "Open Settings › Apps and pick an app from this list.",
                "Turn off anything it doesn't need: Location, Photos, Contacts, Microphone, Camera.",
                "For apps that contact tracking companies, turn off Allow Tracking, or delete apps you no longer use.",
            ], tint: Tone.fix.tint)
            Button("Open Settings") { SettingsLink.openSettingsHome() }
                .buttonStyle(PrimaryCTAButtonStyle())
        }
    }

    private func load(_ result: Result<URL, Error>) {
        problem = nil
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let r = try PrivacyReport.read(try Data(contentsOf: url))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { report = r }
            opened += 1
        } catch {
            problem = (error as? LocalizedError)?.errorDescription ?? PrivacyReport.ReadError.notAReport.errorDescription
            Haptics.warning()
        }
    }
}

/// One app: what private data it used and which sites it contacted, tracking companies first.
private struct AppActivityCard: View {
    let app: PrivacyReport.AppActivity
    @State private var showAllSites = false

    var body: some View {
        ToneCard(tone: app.trackerCount > 0 ? .alert : (app.uses.isEmpty ? .context : .explain),
                 title: app.name, symbol: app.uses.isEmpty ? "network" : "app.badge") {
            Text(app.bundleID)
                .font(.caption.monospaced())
                .foregroundStyle(Brand.textSubtle)
                .textSelection(.enabled)
            if !app.uses.isEmpty {
                Text(Brand.brandUppercased("Used"))
                    .font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(Brand.textSubtle)
                FlowRow {
                    ForEach(app.sortedUses, id: \.0) { kind, count in
                        ToneBadge(text: count > 1 ? "\(kind.title) ×\(count)" : kind.title, symbol: kind.symbol, tone: .explain)
                    }
                }
            }
            if !app.sites.isEmpty {
                Text(Brand.brandUppercased(app.trackerCount > 0 ? "Contacted, incl. \(app.trackerCount) tracking" : "Contacted"))
                    .font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(app.trackerCount > 0 ? Tone.alert.tint : Brand.textSubtle)
                let sites = app.sortedSites
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(showAllSites ? sites : Array(sites.prefix(5))) { site in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: site.isTracker ? "eye.trianglebadge.exclamationmark" : "globe")
                                .font(.caption)
                                .foregroundStyle(site.isTracker ? Tone.alert.tint : Brand.textSubtle)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(site.domain)
                                    .font(.subheadline)
                                    .foregroundStyle(site.isTracker ? Brand.ink : Brand.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let owner = site.owner {
                                    Text(owner).font(.caption).foregroundStyle(Brand.textSubtle)
                                }
                            }
                            Spacer(minLength: 6)
                            Text("\(site.hits)×").font(.caption.monospacedDigit()).foregroundStyle(Brand.textSubtle)
                        }
                    }
                }
                if sites.count > 5 {
                    Button(showAllSites ? "Show fewer" : "Show all \(sites.count) sites") {
                        withAnimation(.snappy) { showAllSites.toggle() }
                        Haptics.selection()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.sand)
                }
            }
        }
    }
}
#endif
