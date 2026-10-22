// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

/// The Tracker tab: the person's own App Privacy Report, opened from Files and read on the device,
/// judged plainly. Only sharing with outside advertising or analytics companies is flagged.
/// Kept only while this screen is open, never saved or sent.
struct PrivacyReportView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var report: PrivacyReport?
    @State private var importing = false
    @State private var problem: String?
    @State private var opened = 0
    @State private var showNormal = false
    var onNext: (() -> Void)? = nil

    private static let types: [UTType] = [UTType(filenameExtension: "ndjson") ?? .data, .json, .plainText, .data]

    var body: some View {
        NavigationStack {
            Page {
                HeroCard(eyebrow: "Tracker",
                         title: report == nil ? "What did your apps do?" : "Here's what they did",
                         subtitle: "Your device keeps a record of which apps used your private data and who they talked to. Open it here and I'll explain it plainly.",
                         mood: report == nil ? .thinking : (report!.sharing.isEmpty ? .happy : .concerned),
                         mascotSize: 96)

                if let report {
                    results(report)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                } else {
                    howTo
                }

                if let problem {
                    ToneCard(tone: .alert, title: "Couldn't read that file", symbol: "exclamationmark.triangle") {
                        Text(problem).font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Before a report: the one action. After: a quiet way to open a newer one.
                if report == nil {
                    Button("Open my report") { importing = true }
                        .buttonStyle(PrimaryCTAButtonStyle())
                    Label {
                        Text("Read only on this device. Nothing is saved or sent, and it's cleared when you leave.")
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: { Image(systemName: "lock.fill").foregroundStyle(Brand.sand) }
                    .font(.footnote)
                    .foregroundStyle(Brand.textSubtle)
                } else {
                    Button("Open a newer report") { importing = true }
                        .buttonStyle(GhostButtonStyle())
                        .frame(maxWidth: .infinity)
                }

                if let onNext, report != nil { NextStepCard(step: .checkup, action: onNext) }
            }
            .navigationTitle("Tracker")
            .inlineTitle()
            .clearNavigationBar()
            .fileImporter(isPresented: $importing, allowedContentTypes: Self.types) { result in load(result) }
            .onChange(of: scenePhase) { _, phase in if phase == .background { report = nil } }
            .task { if CommandLine.arguments.contains("-sampleData") && report == nil { report = .sample } }
            .sensoryFeedback(trigger: opened) { _, _ in (report?.sharing.isEmpty ?? true) ? .success : .warning }
        }
    }

    private var howTo: some View {
        ToneCard(tone: .explain, title: "Get your report", symbol: "doc.text.magnifyingglass") {
            StepList(steps: [
                "Open Settings › Privacy & Security › App Privacy Report. If it's off, turn it on and come back in a few days.",
                "Tap the Share button at the top right, then Save to Files.",
                "Come back here and tap Open my report.",
            ], tint: Tone.explain.tint)
            Button("Open Settings") { SettingsLink.openSettingsHome() }
                .buttonStyle(GhostButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func results(_ r: PrivacyReport) -> some View {
        let ranked = r.ranked
        let worth = ranked.filter { $0.verdict == .sharesOutside || $0.verdict == .contentTrackers }
        let used = ranked.filter { $0.verdict == .usedData }
        let calm = ranked.filter { $0.verdict == .normal || $0.verdict == .crashReports }

        SummaryRing(slices: [
            .alert(worth.count, "worth a look"),
            .amber(used.count, "used data, nothing shared"),
            .fine(calm.count, "nothing unusual"),
        ], caption: "apps")

        ToneCard(tone: r.sharing.isEmpty ? .fix : .alert, title: "In short", symbol: "text.magnifyingglass") {
            VStack(alignment: .leading, spacing: 10) {
                summaryLine(r.sharing.count, one: "app shared data with outside advertising or analytics companies",
                            many: "apps shared data with outside advertising or analytics companies", tone: r.sharing.isEmpty ? .fix : .alert)
                if !used.isEmpty { summaryLine(used.count, one: "app used your private data without sharing it",
                            many: "apps used your private data without sharing it", tone: .explain) }
                if !calm.isEmpty { summaryLine(calm.count, one: "app did nothing unusual", many: "apps did nothing unusual", tone: .fix) }
            }
        }

        limitsCard(r)
        appListCard(r)

        if !worth.isEmpty {
            SectionTitle(title: "Worth a look", trailing: "\(worth.count)")
            ForEach(worth) { app in AppActivityCard(app: app) }
        }
        if !used.isEmpty {
            SectionTitle(title: "Used your data, nothing shared", trailing: "\(used.count)")
            ForEach(used) { app in AppActivityCard(app: app) }
        }
        if !calm.isEmpty {
            ToneCard(tone: .fix, title: "Nothing unusual", symbol: "checkmark.seal") {
                Text("\(calm.count) apps only talked to their own servers, Apple, or the sign-in and hosting services apps are built on. Some send crash reports, which is usually harmless.")
                    .font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
                Button(showNormal ? "Hide them" : "Show them") {
                    withAnimation(reduceMotion ? nil : .snappy) { showNormal.toggle() }
                    Haptics.selection()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Tone.fix.tint)
            }
            if showNormal {
                ForEach(calm) { app in AppActivityCard(app: app).transition(.opacity) }
            }
        }

        ToneCard(tone: .fix, title: "Take access back", symbol: "wrench.and.screwdriver") {
            StepList(steps: [
                "Open Settings › Apps and pick an app from the list above.",
                "Turn off anything it doesn't need: Location, Photos, Contacts, Microphone, Camera.",
                "Turn off Allow Tracking for apps that share with advertising companies, or delete apps you no longer use.",
            ], tint: Tone.fix.tint)
            Button("Open Settings") { SettingsLink.openSettingsHome() }
                .buttonStyle(PrimaryCTAButtonStyle())
        }
    }

    private func summaryLine(_ n: Int, one: String, many: String, tone: Tone) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(n)").font(.title3.weight(.bold).monospacedDigit()).foregroundStyle(tone.tint).frame(minWidth: 28, alignment: .leading)
            Text(n == 1 ? one : many).font(.subheadline).foregroundStyle(Brand.ink).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// What the report can't show, said up front so nobody reads silence as all-clear.
    private func limitsCard(_ r: PrivacyReport) -> some View {
        ToneCard(tone: .limit, title: "What this report can't show", symbol: "calendar.badge.exclamationmark") {
            VStack(alignment: .leading, spacing: 8) {
                bullet("It covers only the last 7 days\(r.from.map { ", from \($0.formatted(date: .abbreviated, time: .omitted))" } ?? ""). Apps that send things when first installed, or only now and then, may not appear.")
                bullet("It shows who an app talked to, not what it sent.")
                bullet("Sites are named by their address. We explain the ones we know; the rest are usually the app's own content.")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle().fill(Tone.limit.tint.opacity(0.7)).frame(width: 5, height: 5)
            Text(text).font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The question people most want answered, answered honestly.
    private func appListCard(_ r: PrivacyReport) -> some View {
        ToneCard(tone: .explain, title: "Did any app send my list of apps?", symbol: "questionmark.app") {
            Text("Nothing on your device records that: the system doesn't log when an app checks which other apps you have, and this report can't see inside what apps send.")
                .font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
            if r.sharing.isEmpty {
                Text("No app here shared data with an outside advertising or analytics company, so there's nowhere obvious it could have gone.")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Tone.fix.tint).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("What it does show: \(r.sharing.count == 1 ? "one app" : "\(r.sharing.count) apps") shared data with outside advertising or analytics companies. That's where details like that usually end up:")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink).fixedSize(horizontal: false, vertical: true)
                FlowRow {
                    ForEach(r.sharing.prefix(12)) { app in ToneBadge(text: app.name, tone: .alert) }
                }
            }
        }
    }

    private func load(_ result: Result<URL, Error>) {
        problem = nil
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let r = try PrivacyReport.read(try Data(contentsOf: url))
            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85)) { report = r; showNormal = false }
            opened += 1
        } catch {
            problem = (error as? LocalizedError)?.errorDescription ?? PrivacyReport.ReadError.notAReport.errorDescription
            Haptics.warning()
        }
    }
}

/// One app, judged plainly: a verdict and why, what it used, and who it talked to, grouped by
/// what each site is. Raw addresses sit behind a tap.
private struct AppActivityCard: View {
    let app: PrivacyReport.AppActivity
    @State private var showSites = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tone: Tone {
        switch app.verdict {
        case .sharesOutside: .alert
        case .contentTrackers, .usedData: .explain
        case .crashReports, .normal: .fix
        }
    }

    private var why: String {
        switch app.verdict {
        case .sharesOutside:
            "It talked to \(app.outsideCompanies.prefix(3).joined(separator: ", "))\(app.outsideCompanies.count > 3 ? " and others" : ""): companies outside the app that record how you use it, for measuring and marketing."
        case .contentTrackers:
            "Something you opened inside it, like an email's images or a web page, loaded a tracker. That's the sender's doing, not the app's."
        case .usedData:
            app.isThisApp ? "That's us: the moments you tapped Show me to see a permission for yourself."
                : app.sites.values.contains(where: { app.kind(of: $0) == .publicData })
                ? "It used your data and asked public services for answers, like the weather or a place name. They get the location they answer for, but don't track you. No advertising or analytics company was contacted."
                : "It used private data, but didn't talk to any outside advertising or analytics company in this report."
        case .crashReports:
            "Besides its own service, it only sends error reports when it crashes. Usually harmless."
        case .normal:
            "It only talked to its own servers, Apple, or the sign-in and hosting services apps are built on."
        }
    }

    var body: some View {
        ToneCard(tone: tone, title: app.name, symbol: app.verdict == .sharesOutside ? "exclamationmark.bubble" : "app") {
            ToneBadge(text: app.verdict.label, tone: tone)
            Text(why).font(.subheadline).foregroundStyle(Brand.textMuted).fixedSize(horizontal: false, vertical: true)
            if app.verdict == .contentTrackers {
                Text("Turn on Settings › Apps › Mail › Privacy Protection to block email trackers.")
                    .font(.footnote).foregroundStyle(Tone.fix.tint).fixedSize(horizontal: false, vertical: true)
            }
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
                Text(Brand.brandUppercased("Talked to"))
                    .font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(Brand.textSubtle)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(app.groups, id: \.0) { kind, sites in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: kind.symbol)
                                .font(.subheadline)
                                .foregroundStyle(kind.isOutsideTracking ? Tone.alert.tint : Brand.textSubtle)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(kind.title) · \(sites.count)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(kind.isOutsideTracking ? Tone.alert.tint : Brand.ink)
                                Text(kind.meaning).font(.footnote).foregroundStyle(Brand.textSubtle).fixedSize(horizontal: false, vertical: true)
                                if showSites {
                                    ForEach(sites) { site in
                                        Text(SiteKind.company(for: site.domain).map { "\($0) · \(site.domain)" } ?? site.domain)
                                            .font(.footnote.monospaced())
                                            .foregroundStyle(Brand.textMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                        }
                    }
                }
                Button(showSites ? "Hide addresses" : "Show addresses") {
                    withAnimation(reduceMotion ? nil : .snappy) { showSites.toggle() }
                    Haptics.selection()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.sand)
            }
        }
    }
}
#endif
