// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import UIKit

/// The installed-app check. iOS only answers for schemes declared in Info.plist
/// `LSApplicationQueriesSchemes` (25 at most with the iOS 27 SDK), so this list must match that
/// array exactly. `SensitiveCatalogueTests` keeps the two in sync.
struct SensitiveCategory: Identifiable, Sendable {
    let id: String
    let title: String
    let symbol: String
    /// Plain words on what an app learns from finding one of these apps: "That tells it …".
    let tells: String
    /// Added after `tells` where simply having the app can be dangerous in some countries.
    let risk: String?
    let apps: [SensitiveApp]
    /// What to do, in order. ``SensitiveCatalogue/deleteStep`` is added after these.
    var steps: [String] = []
}

struct SensitiveApp: Identifiable, Sendable, Hashable {
    let name: String
    let scheme: String
    var id: String { scheme }
}

enum SensitiveCatalogue {
    /// The last step on every card: how to delete, and why hiding isn't enough.
    static let deleteStep = "To delete an app: touch and hold its icon, then Remove App › Delete App. Hiding it doesn't help."

    static let categories: [SensitiveCategory] = [
        .init(id: "dating", title: "Dating and LGBTQ+", symbol: "heart",
              tells: "That tells it you're single or looking, and sometimes who you're attracted to.",
              risk: "In some countries, this alone can put you in danger.",
              apps: [.init(name: "Grindr", scheme: "grindr"), .init(name: "Blued", scheme: "blued"),
                     .init(name: "Tinder", scheme: "tinder"), .init(name: "Bumble", scheme: "bumble")],
              steps: ["Use the website instead, such as tinder.com or bumble.com. Websites can't be spotted this way.",
                      "Delete dating apps while you're not using them. Your matches and profile stay in your account.",
                      "Travelling somewhere this could be risky? Delete the app before you go and reinstall it when you're back."]),
        .init(id: "faith", title: "Religion and faith", symbol: "book.closed",
              tells: "That tells it your religion.",
              risk: nil,
              apps: [.init(name: "Muslim Pro", scheme: "muslimpro"), .init(name: "Bible (YouVersion)", scheme: "youversion")],
              steps: ["If you'd rather keep this private, use the website, or a reading app that isn't tied to one faith."]),
        .init(id: "health", title: "Health and fertility", symbol: "cross.case",
              tells: "That tells it you may track your period, be trying for a baby, or see a therapist.",
              risk: nil,
              apps: [.init(name: "Flo", scheme: "flo"), .init(name: "Clue", scheme: "clue"),
                     .init(name: "Talkspace", scheme: "talkspace"), .init(name: "Headspace", scheme: "headspace")],
              steps: ["Choose apps that keep your data on the device, or let you use them without an account.",
                      "Delete health apps you no longer use, but first ask the app to delete your data."]),
        .init(id: "recovery", title: "Addiction and recovery", symbol: "leaf",
              tells: "That tells it you may be recovering from an addiction.",
              risk: nil,
              apps: [.init(name: "I Am Sober", scheme: "iamsober")],
              steps: ["If you'd rather keep this private, use the service's website instead of the app."]),
        .init(id: "circumvention", title: "VPN, Tor and censorship tools", symbol: "network.badge.shield.half.filled",
              tells: "That tells it you hide your location or get around blocked websites.",
              risk: "In countries that restrict VPNs, this alone can get you questioned.",
              apps: [.init(name: "Psiphon", scheme: "psiphon"), .init(name: "Onion Browser", scheme: "onionhttp"),
                     .init(name: "Proton VPN", scheme: "protonvpn"), .init(name: "NordVPN", scheme: "nordvpn")],
              steps: ["Keep it if you need it. It still hides your address from websites and apps.",
                      "Travelling somewhere VPNs are restricted? Delete it before you go and reinstall it when you're back. Your account stays."]),
        .init(id: "messaging", title: "Private and regional messaging", symbol: "bubble.left.and.bubble.right",
              tells: "That tells it you care about private chats, or hints at where you're from.",
              risk: nil,
              apps: [.init(name: "Signal", scheme: "sgnl"), .init(name: "Telegram", scheme: "tg"),
                     .init(name: "Threema", scheme: "threema"), .init(name: "WeChat", scheme: "weixin")],
              steps: ["Nothing urgent. These apps are common, so they say little on their own.",
                      "If one hints at where you're from and that worries you, use its computer or web version instead."]),
        .init(id: "money", title: "Crypto and gambling", symbol: "bitcoinsign.circle",
              tells: "That tells it you own crypto or bet, which makes you a target for scams.",
              risk: nil,
              apps: [.init(name: "Binance", scheme: "bnc"), .init(name: "Coinbase", scheme: "coinbase"),
                     .init(name: "MetaMask", scheme: "metamask"), .init(name: "bet365", scheme: "bet365")],
              steps: ["Expect scam messages. Never share your recovery phrase or sign-in codes with anyone.",
                      "Turn on two-step sign-in in each app."]),
        .init(id: "work", title: "Job hunting and workplace", symbol: "briefcase",
              tells: "That tells it you may talk anonymously about your job, or be looking for a new one.",
              risk: nil,
              apps: [.init(name: "Blind", scheme: "teamblind")],
              steps: ["If your employer manages this device, keep job-hunting and workplace apps on a personal device."]),
        .init(id: "politics", title: "Politics and news", symbol: "newspaper",
              tells: "That hints at your political views, from the news you read.",
              risk: nil,
              apps: [.init(name: "Fox News", scheme: "foxnews")],
              steps: ["Read the news in your browser instead, if you'd rather keep your views private."]),
    ]

    static var allSchemes: [String] { categories.flatMap { $0.apps.map(\.scheme) } }

    /// Asks iOS about each app in the chosen categories. Returns the apps found.
    @MainActor
    static func scan(_ categoryIDs: Set<String>) -> [String: [SensitiveApp]] {
        var found: [String: [SensitiveApp]] = [:]
        for category in categories where categoryIDs.contains(category.id) {
            found[category.id] = category.apps.filter { app in
                URL(string: "\(app.scheme)://").map(UIApplication.shared.canOpenURL) ?? false
            }
        }
        return found
    }
}
