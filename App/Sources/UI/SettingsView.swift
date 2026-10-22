// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import StoreKit
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
    @Environment(\.requestReview) private var requestReview
    @AppStorage("reviewCardTapped") private var reviewTapped = false
    @State private var confirmingClear = false
    @AppStorage(ScanReminder.storageKey) private var reminder = ScanReminder.off.rawValue
    @State private var notificationsOff = false

    static let shareMessage = "hYYa Footprint Inspector shows what any app can learn about your device, and how to fix it. Free, open source, nothing leaves your device."

    var body: some View {
        NavigationStack {
            Page {
                HeroCard(eyebrow: "Settings", title: "hYYa Footprint Inspector",
                         subtitle: "Everything here stays on this device.", mood: .idle, mascotSize: 96)

                ReviewCard()

                SectionTitle(title: "Your scans")
                Panel {
                    NavigationLink { HistoryView() } label: {
                        RowCard(symbol: "clock.arrow.circlepath", title: "Scan history") {
                            HStack(spacing: 8) { Text("\(history.snapshots.count)"); Image(systemName: "chevron.right") }
                        }
                    }
                    .buttonStyle(PressableCardStyle())
                    NavigationLink { ScoreboardView() } label: {
                        RowCard(symbol: "checkmark.seal", title: "Privacy scoreboard")
                    }
                    .buttonStyle(PressableCardStyle())
                    Menu {
                        ForEach(ScanReminder.allCases) { option in
                            Button { choose(option) } label: {
                                if option.rawValue == reminder { Label(option.title, systemImage: "checkmark") } else { Text(option.title) }
                            }
                        }
                    } label: {
                        RowCard(symbol: "bell", title: "Re-scan reminder",
                                subtitle: "A reminder on this device to check again.") {
                            HStack(spacing: 6) {
                                Text(ScanReminder(rawValue: reminder)?.title ?? "Off")
                                Image(systemName: "chevron.up.chevron.down")
                            }
                        }
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

                // Same order as Encrypted Notes. Share and Rate carry subtitles because they're asks;
                // the other three are errands the user already knows the reason for.
                SectionTitle(title: "Support hYYa")
                Panel {
                    ShareLink(item: hYYaLinks.shareTarget, message: Text(Self.shareMessage)) {
                        RowCard(symbol: "square.and.arrow.up", title: "Share", subtitle: "Help your friends take back their digital privacy.")
                    }
                    .buttonStyle(PressableCardStyle())
                    Button { rate() } label: {
                        RowCard(symbol: "star", title: "Rate the App", subtitle: "Your reviews keep us smiling while coding.")
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
                        RowCard(symbol: "lock.shield", title: "Report a Security Issue") { Image(systemName: "arrow.up.right") }
                    }
                    .buttonStyle(PressableCardStyle())
                }

                SectionTitle(title: "More from hYYa")
                Panel {
                    PromoRow(imageName: "PromoHyyaAI", title: "hYYa ai", tagline: "Two engines. Offline & Online.", url: hYYaLinks.hyyaAIAppStore)
                    PromoRow(imageName: "HyyaDev", title: "hYYa \u{2728}", tagline: "Companions you can trust.", url: hYYaLinks.website)
                }

                #if DEBUG && os(iOS)
                SectionTitle(title: "Developer")
                Panel {
                    NavigationLink { SettingsLinkLab() } label: { RowCard(symbol: "hammer", title: "Settings link lab") }
                        .buttonStyle(PressableCardStyle())
                }
                #endif

                VStack(spacing: Brand.Space.sm) {
                    SectionDivider()
                    Image("MascotCutout")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 82)
                        .accessibilityHidden(true)
                    Text(Brand.brandUppercased("hYYa Footprint Inspector"))
                        .font(.caption2.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(Brand.textSubtle)
                    Text("Version \(Self.version) · Open source, MPL 2.0")
                        .font(.caption)
                        .foregroundStyle(Brand.textSubtle)
                    Button { open(hYYaLinks.source) } label: {
                        Label("View the source code", systemImage: "arrow.up.right")
                            .labelStyle(TrailingIconLabelStyle())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.sand)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .hiddenNavigationBar()
            .alert("Notifications are off", isPresented: $notificationsOff) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("To get a re-scan reminder, allow notifications for hYYa Footprint Inspector in Settings, then choose a reminder again.")
            }
            .confirmationDialog("Clear all saved scans?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) { history.clear(); Haptics.success() }
            } message: {
                Text("Your score history and before/after comparisons start over.")
            }
        }
    }

    /// Picking a reminder schedules it at once; if notifications are declined it returns to Off.
    private func choose(_ choice: ScanReminder) {
        reminder = choice.rawValue
        Haptics.selection()
        Task {
            if await !choice.apply() {
                reminder = ScanReminder.off.rawValue
                notificationsOff = true
            }
        }
    }

    /// Same behaviour as the rating card at the top.
    private func rate() {
        Haptics.selection()
        reviewTapped = true
        if let url = hYYaLinks.appStoreReview { openURL(url) } else { requestReview() }
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

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) { configuration.title; configuration.icon }
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
