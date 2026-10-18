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
    /// One calm sentence on what an app could guess.
    let inference: String
    /// Shown before scanning, for categories where simply having the apps can be risky.
    let caution: String?
    let apps: [SensitiveApp]
    /// What to do when apps in this category answered. Calm and practical.
    var advice: [String] = []
}

struct SensitiveApp: Identifiable, Sendable, Hashable {
    let name: String
    let scheme: String
    var id: String { scheme }
}

enum SensitiveCatalogue {
    static let riskyCountriesCaution = "In some countries, having these apps can be risky. This check runs only on your device, and only you see the result."

    static let categories: [SensitiveCategory] = [
        .init(id: "dating", title: "Dating and LGBTQ+", symbol: "heart",
              inference: "An app could guess you're single or looking, and sometimes your sexual orientation.",
              caution: riskyCountriesCaution,
              apps: [.init(name: "Grindr", scheme: "grindr"), .init(name: "Blued", scheme: "blued"),
                     .init(name: "Tinder", scheme: "tinder"), .init(name: "Bumble", scheme: "bumble")],
              advice: ["Use the website instead of the app where it has one, such as tinder.com or bumble.com. A website can’t be detected this way.", "Delete dating apps while you’re not using them. Your matches and profile stay in your account.", "Before travelling somewhere this could be risky, delete the app and reinstall it when you’re back."]),
        .init(id: "faith", title: "Religion and faith", symbol: "book.closed",
              inference: "An app could guess your religion.",
              caution: nil,
              apps: [.init(name: "Muslim Pro", scheme: "muslimpro"), .init(name: "Bible (YouVersion)", scheme: "youversion")],
              advice: ["If you’d rather keep this private, use the website, or a general reading app that isn’t tied to one faith."]),
        .init(id: "health", title: "Health and fertility", symbol: "cross.case",
              inference: "An app could guess that you track your cycle, are trying for a baby, or see a therapist.",
              caution: nil,
              apps: [.init(name: "Flo", scheme: "flo"), .init(name: "Clue", scheme: "clue"),
                     .init(name: "Talkspace", scheme: "talkspace"), .init(name: "Headspace", scheme: "headspace")],
              advice: ["Prefer apps that keep your data on the device or offer an anonymous mode.", "Delete health apps you no longer use, after asking the app to delete your data."]),
        .init(id: "recovery", title: "Addiction and recovery", symbol: "leaf",
              inference: "An app could guess you're recovering from a dependence.",
              caution: nil,
              apps: [.init(name: "I Am Sober", scheme: "iamsober")],
              advice: ["If you’d rather keep this private, use the service’s website instead of the app."]),
        .init(id: "circumvention", title: "VPN, Tor and censorship tools", symbol: "network.badge.shield.half.filled",
              inference: "An app could guess you work around network controls.",
              caution: riskyCountriesCaution,
              apps: [.init(name: "Psiphon", scheme: "psiphon"), .init(name: "Onion Browser", scheme: "onionhttp"),
                     .init(name: "Proton VPN", scheme: "protonvpn"), .init(name: "NordVPN", scheme: "nordvpn")],
              advice: ["Keep using these tools if you need them: a VPN still hides your address from websites and apps.", "Where these tools are restricted, delete them before border checks and reinstall later."]),
        .init(id: "messaging", title: "Private and regional messaging", symbol: "bubble.left.and.bubble.right",
              inference: "An app could guess you value private chats, or roughly where you're from.",
              caution: nil,
              apps: [.init(name: "Signal", scheme: "sgnl"), .init(name: "Telegram", scheme: "tg"),
                     .init(name: "Threema", scheme: "threema"), .init(name: "WeChat", scheme: "weixin")],
              advice: ["Nothing urgent. These apps are common, so they say little on their own.", "If one hints at where you’re from and that worries you, use its desktop or web version instead."]),
        .init(id: "money", title: "Crypto and gambling", symbol: "bitcoinsign.circle",
              inference: "An app could guess you hold crypto or gamble, which makes you a target for scams.",
              caution: nil,
              apps: [.init(name: "Binance", scheme: "bnc"), .init(name: "Coinbase", scheme: "coinbase"),
                     .init(name: "MetaMask", scheme: "metamask"), .init(name: "bet365", scheme: "bet365")],
              advice: ["Expect scam messages: crypto and betting users are targeted. Never share recovery phrases or codes.", "Turn on two-factor sign-in in each app."]),
        .init(id: "work", title: "Job hunting and workplace", symbol: "briefcase",
              inference: "An app could guess you talk anonymously about your workplace, or are looking to leave.",
              caution: nil,
              apps: [.init(name: "Blind", scheme: "teamblind")],
              advice: ["If your employer manages this device, keep job-hunting and workplace-forum apps on a personal device."]),
        .init(id: "politics", title: "Politics and news", symbol: "newspaper",
              inference: "An app could guess your political leaning from the news you read.",
              caution: nil,
              apps: [.init(name: "Fox News", scheme: "foxnews")],
              advice: ["Read news in the browser instead of partisan apps if you’d rather keep your leaning private."]),
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
