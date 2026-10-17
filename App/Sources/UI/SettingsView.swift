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
    /// App Store Connect record created 2026-10-17 (SKU hyya-footprint-inspector). The listing goes
    /// live only once a version is approved, so before launch the Share and Rate links reach a
    /// "not available" App Store page; after launch they resolve.
    static let appStoreID: String? = "6824033636"
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
    @AppStorage(HyyaSuggestions.settingKey) private var showSuggestions = true
    @State private var confirmingClear = false

    static let shareMessage = "hYYa Footprint Inspector shows what any app can learn about your iPhone, and how to fix it. Free, open source, nothing leaves your phone."

    var body: some View {
        NavigationStack {
            Page {
                HeroCard(eyebrow: "Settings", title: "hYYa Footprint Inspector",
                         subtitle: "Everything here stays on this iPhone.", mood: .idle, mascotSize: 96)

                ReviewCard()

                SectionTitle(title: "Your data")
                Panel {
                    NavigationLink { HistoryView() } label: {
                        RowCard(symbol: "clock.arrow.circlepath", title: "Scan history") {
                            HStack(spacing: 8) { Text("\(history.snapshots.count)"); Image(systemName: "chevron.right") }
                        }
                    }
                    .buttonStyle(PressableCardStyle())
                    NavigationLink { ScoreboardView() } label: {
                        RowCard(symbol: "checkmark.seal", title: "iOS scoreboard")
                    }
                    .buttonStyle(PressableCardStyle())
                    Button { confirmingClear = true } label: {
                        RowCard(symbol: "trash", title: "Clear history", tileFG: Brand.concern) { EmptyView() }
                    }
                    .buttonStyle(PressableCardStyle())
                    .disabled(history.snapshots.isEmpty)
                }
                Text("Sensitive-app results are never saved.")
                    .font(.footnote).foregroundStyle(Brand.textSubtle).padding(.horizontal, 4).padding(.top, -14)

                SectionTitle(title: "Suggestions")
                Panel {
                    Toggle(isOn: $showSuggestions) {
                        Text("Suggest hYYa apps in fixes").foregroundStyle(Brand.ink)
                    }
                    .tint(Brand.sand)
                    .padding(16)
                }
                Text("Where one of our apps genuinely helps, it's mentioned after the free fix.")
                    .font(.footnote).foregroundStyle(Brand.textSubtle).padding(.horizontal, 4).padding(.top, -14)

                SectionTitle(title: "Open source")
                Panel {
                    Button { open(hYYaLinks.source) } label: {
                        RowCard(symbol: "chevron.left.forwardslash.chevron.right", title: "Source code", subtitle: "github.com/hyya-dev") {
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    .buttonStyle(PressableCardStyle())
                    RowCard(symbol: "doc.text", title: "Licence") { Text("MPL 2.0") }
                    RowCard(symbol: "number", title: "Version") { Text(Self.version) }
                }

                SectionTitle(title: "Support hYYa")
                Panel {
                    ShareLink(item: hYYaLinks.shareTarget, message: Text(Self.shareMessage)) {
                        RowCard(symbol: "square.and.arrow.up", title: "Share", subtitle: "Help your friends take back their digital privacy.")
                    }
                    .buttonStyle(PressableCardStyle())
                    Button { open(hYYaLinks.contact) } label: {
                        RowCard(symbol: "envelope", title: "Contact hYYa") { Image(systemName: "arrow.up.right") }
                    }
                    .buttonStyle(PressableCardStyle())
                    Button { open(hYYaLinks.privacy) } label: {
                        RowCard(symbol: "hand.raised", title: "Privacy Policy") { Image(systemName: "arrow.up.right") }
                    }
                    .buttonStyle(PressableCardStyle())
                    Button { open(hYYaLinks.security) } label: {
                        RowCard(symbol: "lock.shield", title: "Report a Security Issue", subtitle: "Opens Mail") { Image(systemName: "arrow.up.right") }
                    }
                    .buttonStyle(PressableCardStyle())
                }

                SectionTitle(title: "More from hYYa")
                Panel {
                    PromoRow(imageName: "PromoHyyaAI", title: "hYYa ai", tagline: "Two engines. Offline & Online.", url: hYYaLinks.hyyaAIAppStore)
                    PromoRow(imageName: "HyyaDev", title: "hYYa \u{2728}", tagline: "Companions you can trust.", url: hYYaLinks.website)
                }

                #if DEBUG
                SectionTitle(title: "Developer")
                Panel {
                    NavigationLink { SettingsLinkLab() } label: { RowCard(symbol: "hammer", title: "Settings link lab") }
                        .buttonStyle(PressableCardStyle())
                }
                #endif

                VStack(spacing: Brand.Space.sm) {
                    SectionDivider()
                    Text(Brand.brandUppercased("hYYa Footprint Inspector"))
                        .font(.caption2.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(Brand.textSubtle)
                }
                .frame(maxWidth: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Clear all saved scans?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) { history.clear(); Haptics.success() }
            } message: {
                Text("Your score history and before/after comparisons start over.")
            }
        }
    }

    private func open(_ url: URL) {
        Haptics.selection()
        openURL(url)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { Rectangle().fill(Brand.rule).frame(height: 0.5).padding(.leading, 75) }
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel("\(title). \(tagline)")
        .accessibilityHint((url.host()?.hasSuffix("apple.com") ?? false) ? "Opens the App Store" : "Opens in your browser")
    }
}
