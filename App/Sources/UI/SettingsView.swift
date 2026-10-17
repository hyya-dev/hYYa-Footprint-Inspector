// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

enum hYYaLinks {
    static let website = URL(string: "https://hyya.com")!
    static let hyyaAIAppStore = URL(string: "https://apps.apple.com/app/id6767114813")!
    static let contact = URL(string: "https://hyya.com/#contact")!
    /// ⚠️ Page owed by hyya.com before launch (HANDOFF.md).
    static let privacy = URL(string: "https://hyya.com/privacypolicy/hyya-footprint-inspector.html")!
    static let security = URL(string: "mailto:security@hyya.com?subject=Security%20report%20%E2%80%94%20hYYa%20Footprint%20Inspector")!
    static let source = URL(string: "https://github.com/hyya-dev/hYYa-Footprint-Inspector")!
    /// ⚠️ Showcase page owed by hyya.com. Used for Share until the App Store id exists.
    static let showcase = URL(string: "https://hyya.com/hyya-footprint-inspector.html")!
    /// Set once the app has an App Store record. While `nil`, "Rate the App" is hidden: a button
    /// that leads nowhere is worse than no button.
    static let appStoreID: String? = nil
    static var appStoreReview: URL? {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)?action=write-review") }
    }
    static var shareTarget: URL {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)") } ?? showcase
    }
}

struct SettingsView: View {
    @Environment(HistoryStore.self) private var history
    @Environment(\.openURL) private var openURL
    @AppStorage("theme") private var theme: AppTheme = .auto
    @AppStorage(HyyaSuggestions.settingKey) private var showSuggestions = true
    @State private var confirmingClear = false

    static let shareMessage = "hYYa Footprint Inspector shows what any app can learn about your iPhone, and how to fix it. Free, open source, nothing leaves your phone."

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Theme", selection: $theme) {
                        ForEach(AppTheme.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                }

                Section {
                    NavigationLink { HistoryView() } label: {
                        LabeledContent {
                            Text("\(history.snapshots.count)")
                        } label: {
                            Label("Scan history", systemImage: "clock.arrow.circlepath")
                        }
                    }
                    NavigationLink { ScoreboardView() } label: {
                        Label("iOS scoreboard", systemImage: "checkmark.seal")
                    }
                    Button(role: .destructive) { confirmingClear = true } label: {
                        Label("Clear history", systemImage: "trash")
                    }
                    .disabled(history.snapshots.isEmpty)
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Everything stays on this iPhone. Sensitive-app results are never saved.")
                }

                Section {
                    Toggle(isOn: $showSuggestions) {
                        Label("Suggest hYYa apps in fixes", systemImage: "lightbulb")
                    }
                } footer: {
                    Text("Where one of our apps genuinely helps with a fix, we mention it after the free fix. Turn this off to hide them.")
                }

                Section {
                    Button { openURL(hYYaLinks.source) } label: {
                        Label("Source code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    LabeledContent("Licence", value: "MPL 2.0")
                    LabeledContent("Version", value: Self.version)
                } header: {
                    Text("Open source")
                } footer: {
                    Text("No account, no server, no analytics. Read the code to check.")
                }

                supportSection
                moreSection

                Section {
                    VStack(spacing: Brand.Space.sm) {
                        MascotEmblem(size: 82)
                        Text(Brand.brandUppercased("hYYa Footprint Inspector"))
                            .font(.caption2.weight(.heavy))
                            .tracking(1.4)
                            .foregroundStyle(Brand.textSubtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Brand.Space.sm)
                    .listRowBackground(Color.clear)
                }
            }
            .brandListBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Clear all saved scans?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) { history.clear(); Haptics.success() }
            } message: {
                Text("Your score history and before/after comparisons start over.")
            }
        }
    }

    private var supportSection: some View {
        Section {
            ShareLink(item: hYYaLinks.shareTarget, message: Text(Self.shareMessage)) {
                SupportRow(symbol: "square.and.arrow.up", title: "Share", tagline: "Help your friends take back their digital privacy.")
            }
            if let review = hYYaLinks.appStoreReview {
                Button { Haptics.selection(); openURL(review) } label: {
                    SupportRow(symbol: "star", title: "Rate the App", tagline: "Your reviews keep us smiling while coding.")
                }
            }
            Button { Haptics.selection(); openURL(hYYaLinks.contact) } label: {
                Label("Contact hYYa", systemImage: "envelope")
            }
            Button { Haptics.selection(); openURL(hYYaLinks.privacy) } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Button { Haptics.selection(); openURL(hYYaLinks.security) } label: {
                Label("Report a Security Issue", systemImage: "lock.shield.fill")
            }
        } header: {
            Text(Brand.brandUppercased("Support hYYa"))
        }
    }

    private var moreSection: some View {
        Section {
            PromoRow(imageName: "PromoHyyaAI", title: "hYYa ai", tagline: "Two engines. Offline & Online.", url: hYYaLinks.hyyaAIAppStore)
            PromoRow(imageName: "HyyaDev", title: "hYYa \u{2728}", tagline: "Companions you can trust.", url: hYYaLinks.website)
        } header: {
            Text(Brand.brandUppercased("More from hYYa"))
        }
    }

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

struct SupportRow: View {
    let symbol: String
    let title: String
    let tagline: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Brand.iconTint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.bold)).foregroundStyle(Brand.textPrimary)
                Text(tagline)
                    .lineLimit(1)
                    .minimumScaleFactor(Brand.shrinkToFitFloor)
                    .font(.caption)
                    .foregroundStyle(Brand.textSubtle)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSubtle)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct PromoRow: View {
    @Environment(\.openURL) private var openURL
    let imageName: String
    let title: String
    let tagline: String
    let url: URL

    var body: some View {
        Button { Haptics.selection(); openURL(url) } label: {
            HStack(spacing: 13) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.bold)).foregroundStyle(Brand.textPrimary)
                    Text(tagline)
                        .lineLimit(1)
                        .minimumScaleFactor(Brand.shrinkToFitFloor)
                        .font(.caption)
                        .foregroundStyle(Brand.textSubtle)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSubtle)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(tagline)")
        .accessibilityHint((url.host()?.hasSuffix("apple.com") ?? false) ? "Opens the App Store" : "Opens in your browser")
    }
}
