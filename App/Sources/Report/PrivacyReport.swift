// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// The device's own App Privacy Report, read from the file the person saves in Settings
/// (Privacy & Security › App Privacy Report › Save App Activity). It's the only record of what
/// other apps actually did: which private data they used and which sites they contacted. No app
/// can see this on its own; the person hands us the file, we read it on the device and keep
/// nothing (docs/WATCHERS-RESEARCH.md).
///
/// The file is newline-delimited JSON. Two layouts are in the wild, so both are read:
/// - current: `{"type":"access","accessor":{"identifier":…},"category":"photos","kind":"intervalBegin",…}`
///   and `{"type":"networkActivity","bundleID":…,"domain":…,"domainOwner":…,"hits":…,"initiatedType":…}`
/// - older: `{"stream":"com.apple.privacy.accounting.stream.tcc","accessor":{…},"tccService":"kTCCServicePhotos",…}`
struct PrivacyReport: Sendable {
    enum DataKind: String, CaseIterable, Sendable, Comparable {
        case location, photos, contacts, camera, microphone, calendars, reminders, media, screen, motion, bluetooth, other

        var title: String {
            switch self {
            case .location: "Location"
            case .photos: "Photos"
            case .contacts: "Contacts"
            case .camera: "Camera"
            case .microphone: "Microphone"
            case .calendars: "Calendars"
            case .reminders: "Reminders"
            case .media: "Music and media"
            case .screen: "Screen recording"
            case .motion: "Motion and fitness"
            case .bluetooth: "Bluetooth"
            case .other: "Other data"
            }
        }

        var symbol: String {
            switch self {
            case .location: "location"
            case .photos: "photo.on.rectangle"
            case .contacts: "person.2"
            case .camera: "camera"
            case .microphone: "mic"
            case .calendars: "calendar"
            case .reminders: "checklist"
            case .media: "music.note"
            case .screen: "rectangle.dashed.badge.record"
            case .motion: "figure.walk"
            case .bluetooth: "dot.radiowaves.left.and.right"
            case .other: "lock"
            }
        }

        static func < (a: DataKind, b: DataKind) -> Bool {
            allCases.firstIndex(of: a)! < allCases.firstIndex(of: b)!
        }

        /// Both layouts' names for the same thing.
        init(raw: String) {
            switch raw.lowercased() {
            case "location", "ktccservicelocation": self = .location
            case "photos", "ktccservicephotos", "ktccservicephotosadd": self = .photos
            case "contacts", "ktccserviceaddressbook": self = .contacts
            case "camera", "ktccservicecamera": self = .camera
            case "microphone", "ktccservicemicrophone": self = .microphone
            case "calendars", "calendar", "ktccservicecalendar": self = .calendars
            case "reminders", "ktccservicereminders": self = .reminders
            case "medialibrary", "ktccservicemedialibrary": self = .media
            case "screenrecording", "ktccservicescreencapture": self = .screen
            case "motion", "ktccservicemotion": self = .motion
            case "bluetooth", "ktccservicebluetoothalways": self = .bluetooth
            default: self = .other
            }
        }
    }

    struct Site: Sendable, Identifiable {
        let domain: String
        let owner: String?
        let hits: Int
        /// True when the app itself opened the connection (not a web page inside it).
        let byApp: Bool
        var id: String { domain }
        var isTracker: Bool { Trackers.matches(domain) }
    }

    struct AppActivity: Sendable, Identifiable {
        let bundleID: String
        var uses: [DataKind: Int] = [:]
        var lastUse: Date?
        var sites: [String: Site] = [:]
        var id: String { bundleID }

        var name: String { bundleID == Bundle.main.bundleIdentifier ? "hYYa Footprint Inspector (this app)" : AppNames.name(for: bundleID) }
        /// This app shows up when the person tapped "Show me" on a permission.
        var isThisApp: Bool { bundleID == Bundle.main.bundleIdentifier }
        var sortedUses: [(DataKind, Int)] { uses.sorted { $0.key < $1.key }.map { ($0.key, $0.value) } }
        var sortedSites: [Site] {
            sites.values.sorted { ($0.isTracker ? 0 : 1, -$0.hits, $0.domain) < ($1.isTracker ? 0 : 1, -$1.hits, $1.domain) }
        }
        var trackerCount: Int { sites.values.filter(\.isTracker).count }
        /// Apps that used private data and also contacted tracking companies come first.
        var weight: Int { uses.values.reduce(0, +) * 3 + trackerCount * 10 + sites.count }
    }

    var apps: [AppActivity]
    var from: Date?
    var to: Date?

    var appsUsingData: Int { apps.filter { !$0.uses.isEmpty }.count }
    var appsContactingSites: Int { apps.filter { !$0.sites.isEmpty }.count }
    var trackerSites: Int { Set(apps.flatMap { $0.sites.values.filter(\.isTracker).map(\.domain) }).count }

    enum ReadError: Error, LocalizedError {
        case notAReport
        var errorDescription: String? {
            "This doesn't look like an App Privacy Report. In Settings › Privacy & Security › App Privacy Report, tap Save App Activity, then open the file it saves."
        }
    }

    static func read(_ data: Data) throws -> PrivacyReport {
        var byApp: [String: AppActivity] = [:]
        var first: Date?, last: Date?
        var recognised = 0
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        func date(_ any: Any?) -> Date? {
            guard let s = any as? String else { return nil }
            return iso.date(from: s) ?? isoPlain.date(from: s)
        }
        func note(_ d: Date?) {
            guard let d else { return }
            first = min(first ?? d, d); last = max(last ?? d, d)
        }

        for line in data.split(separator: UInt8(ascii: "\n")) where !line.isEmpty {
            guard let obj = (try? JSONSerialization.jsonObject(with: Data(line))) as? [String: Any] else { continue }
            let type = obj["type"] as? String
            let stream = obj["stream"] as? String
            if type == "networkActivity", let bundle = obj["bundleID"] as? String, let domain = obj["domain"] as? String, !domain.isEmpty {
                recognised += 1
                var app = byApp[bundle] ?? AppActivity(bundleID: bundle)
                let hits = (obj["hits"] as? Int) ?? 1
                let old = app.sites[domain]
                app.sites[domain] = Site(domain: domain, owner: (obj["domainOwner"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? old?.owner,
                                         hits: (old?.hits ?? 0) + hits,
                                         byApp: (old?.byApp ?? false) || (obj["initiatedType"] as? String ?? "AppInitiated") == "AppInitiated")
                byApp[bundle] = app
                note(date(obj["timeStamp"])); note(date(obj["firstTimeStamp"]))
            } else if type == "access" || stream?.contains("tcc") == true || stream?.contains("location") == true,
                      let accessor = obj["accessor"] as? [String: Any], let bundle = accessor["identifier"] as? String {
                recognised += 1
                let kind = obj["kind"] as? String
                // An access is logged as a begin/end pair; count each use once.
                guard kind != "intervalEnd" else { continue }
                let raw = (obj["category"] as? String) ?? (obj["tccService"] as? String) ?? (stream?.contains("location") == true ? "location" : "other")
                var app = byApp[bundle] ?? AppActivity(bundleID: bundle)
                app.uses[DataKind(raw: raw), default: 0] += 1
                let when = date(obj["timeStamp"]) ?? date(obj["timestamp"])
                if let when { app.lastUse = max(app.lastUse ?? when, when) }
                byApp[bundle] = app
                note(when)
            }
        }
        guard recognised > 0 else { throw ReadError.notAReport }
        return PrivacyReport(apps: byApp.values.sorted { ($0.weight, $1.name) > ($1.weight, $0.name) }, from: first, to: last)
    }
}

/// Well-known advertising, analytics and tracking companies, matched by domain suffix. Used only
/// to label sites in the report; no site is called malicious. Kept short and conservative.
enum Trackers {
    static let suffixes: [String] = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com", "google-analytics.com",
        "app-measurement.com", "firebaselogging-pa.googleapis.com", "crashlytics.com", "adservice.google.com",
        "graph.facebook.com", "connect.facebook.net", "an.facebook.com",
        "adjust.com", "adjust.io", "appsflyer.com", "appsflyersdk.com", "branch.io", "app.link", "kochava.com", "singular.net",
        "onesignal.com", "amplitude.com", "mixpanel.com", "segment.io", "segment.com", "braze.com", "appboy.com",
        "applovin.com", "applvn.com", "unityads.unity3d.com", "ironsrc.com", "ironsrc.mobi", "chartboost.com",
        "adcolony.com", "vungle.com", "inmobi.com", "criteo.com", "criteo.net", "taboola.com", "outbrain.com",
        "scorecardresearch.com", "moatads.com", "adnxs.com", "rubiconproject.com", "pubmatic.com", "smaato.net",
        "ads.tiktok.com", "analytics.tiktok.com", "ads-api.twitter.com", "analytics.twitter.com", "sc-analytics.appspot.com",
        "app-analytics-services.com", "crashlyticsreports-pa.googleapis.com", "googletagmanager.com", "awstrack.me",
        "bugsnag.com", "sentry.io", "newrelic.com", "nr-data.net", "datadoghq.com", "instabug.com", "flurry.com",
    ]

    static func matches(_ domain: String) -> Bool {
        let d = domain.lowercased()
        return suffixes.contains { d == $0 || d.hasSuffix("." + $0) }
    }
}

/// A readable name for an app the report names only by its bundle ID. Common apps by ID; anything
/// else from the ID's last part ("com.example.notes" → "Notes"), shown with the ID underneath.
enum AppNames {
    static let known: [String: String] = [
        "com.burbn.instagram": "Instagram", "com.facebook.Facebook": "Facebook", "net.whatsapp.WhatsApp": "WhatsApp",
        "com.facebook.Messenger": "Messenger", "com.zhiliaoapp.musically": "TikTok", "com.atebits.Tweetie2": "X",
        "ph.telegra.Telegraph": "Telegram", "org.whispersystems.signal": "Signal", "com.toyopagroup.picaboo": "Snapchat",
        "com.google.ios.youtube": "YouTube", "com.google.Gmail": "Gmail", "com.google.Maps": "Google Maps",
        "com.google.chrome.ios": "Chrome", "com.google.GoogleMobile": "Google", "com.spotify.client": "Spotify",
        "com.netflix.Netflix": "Netflix", "com.amazon.Amazon": "Amazon", "com.ubercab.UberClient": "Uber",
        "com.linkedin.LinkedIn": "LinkedIn", "com.pinterest": "Pinterest", "com.reddit.Reddit": "Reddit",
        "com.microsoft.Office.Outlook": "Outlook", "com.microsoft.skype.teams": "Microsoft Teams", "us.zoom.videomeetings": "Zoom",
        "com.tencent.xin": "WeChat", "com.viber": "Viber", "com.cardify.tinder": "Tinder", "com.grindrguy.grindrx": "Grindr",
        "com.bumble.app": "Bumble", "com.hinge.app": "Hinge", "com.duolingo.DuolingoMobile": "Duolingo",
        "com.paypal.PPClient": "PayPal", "com.venmo.touch.v2": "Venmo",
        "com.apple.mobilesafari": "Safari", "com.apple.camera": "Camera", "com.apple.mobileslideshow": "Photos",
        "com.apple.Maps": "Maps", "com.apple.MobileSMS": "Messages", "com.apple.mobilemail": "Mail",
        "com.apple.weather": "Weather", "com.apple.Health": "Health", "com.apple.findmy": "Find My",
        // Apple's own apps, whose IDs don't match their names.
        "com.apple.mobilephone": "Phone", "com.apple.AppStore": "App Store", "com.apple.mobilecal": "Calendar",
        "com.apple.SiriApp": "Siri", "com.apple.facetime": "FaceTime", "com.apple.Passbook": "Wallet",
        "com.apple.Passwords": "Passwords", "com.apple.tv": "TV", "com.apple.MobileAddressBook": "Contacts",
        "com.apple.mobilenotes": "Notes", "com.apple.reminders": "Reminders", "com.apple.Music": "Music",
        "com.apple.Fitness": "Fitness", "com.apple.shortcuts": "Shortcuts", "com.apple.TestFlight": "TestFlight",
        "com.apple.mobiletimer": "Clock", "com.apple.Preferences": "Settings", "com.apple.podcasts": "Podcasts",
        // hYYa's apps.
        "com.hyya.prayerpal": "hYYa PrayerPal", "com.hyya.encryptednotes": "hYYa Encrypted Notes",
        "com.hyya.encryptedfolder": "hYYa Encrypted Folder", "com.hyya.subscriptionstracker": "hYYa Subscriptions Tracker",
        "com.hyya.hyya-ai": "hYYa ai", "com.hyya.ink": "hYYa ink", "com.hyya.anarchybrowser": "hYYa Anarchy Browser",
        // Common apps whose IDs don't say their name.
        "com.yourcompany.PPClient": "PayPal", "com.appspot.scruffapp": "Scruff", "com.investing.app": "Investing.com",
        "com.careem.mobile.app.icma": "Careem", "com.czzhao.binance": "Binance", "ch.protonmail.protonmail": "Proton Mail",
        "com.google.Drive": "Google Drive", "com.google.tasks": "Google Tasks", "com.google.Authenticator": "Google Authenticator",
        "com.google.gemini": "Gemini", "com.nordvpn.NordVPN": "NordVPN", "sa.com.STCBank": "STC Bank",
        "com.hungerstation.ios.hungerstationapp": "HungerStation", "com.inomma.coinstats": "CoinStats",
        "com.google.photos": "Google Photos", "com.google.Docs": "Google Docs", "com.microsoft.Office.Word": "Word",
        "com.microsoft.Office.Excel": "Excel", "com.amazon.aiv.AIVApp": "Prime Video", "com.disney.disneyplus": "Disney+",
    ]

    /// ID parts that never name the app.
    private static let generic: Set<String> = ["app", "ios", "iphone", "mobile", "client", "application", "prod", "release", "icma"]

    static func name(for bundleID: String) -> String {
        if let n = known[bundleID] { return n }
        let parts = bundleID.split(separator: ".").map(String.init)
        let last = parts.reversed().first { !generic.contains($0.lowercased()) } ?? parts.last ?? bundleID
        let spaced = last.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }
}

extension PrivacyReport {
    /// A made-up report in the current layout, for tests and store screenshots (never real data).
    static let sampleLines = """
    {"accessor":{"identifier":"com.example.photoeditor","identifierType":"bundleID"},"category":"photos","identifier":"A1","kind":"intervalBegin","timeStamp":"2026-10-20T09:12:00.000+03:00","type":"access"}
    {"accessor":{"identifier":"com.example.photoeditor","identifierType":"bundleID"},"category":"photos","identifier":"A1","kind":"intervalEnd","timeStamp":"2026-10-20T09:12:04.000+03:00","type":"access"}
    {"accessor":{"identifier":"com.example.photoeditor","identifierType":"bundleID"},"category":"location","identifier":"A2","kind":"intervalBegin","timeStamp":"2026-10-21T18:40:00.000+03:00","type":"access"}
    {"accessor":{"identifier":"com.example.weatherplus","identifierType":"bundleID"},"category":"location","identifier":"A3","kind":"intervalBegin","timeStamp":"2026-10-19T07:00:00.000+03:00","type":"access"}
    {"accessor":{"identifier":"com.example.weatherplus","identifierType":"bundleID"},"category":"location","identifier":"A4","kind":"intervalBegin","timeStamp":"2026-10-21T07:00:00.000+03:00","type":"access"}
    {"accessor":{"identifier":"com.example.chat","identifierType":"bundleID"},"category":"contacts","identifier":"A5","kind":"intervalBegin","timeStamp":"2026-10-21T12:00:00.000+03:00","type":"access"}
    {"accessor":{"identifier":"com.example.chat","identifierType":"bundleID"},"category":"microphone","identifier":"A6","kind":"intervalBegin","timeStamp":"2026-10-21T12:05:00.000+03:00","type":"access"}
    {"domain":"api.example-photo.com","firstTimeStamp":"2026-10-20T09:00:00Z","context":"","timeStamp":"2026-10-21T18:41:00Z","domainType":2,"initiatedType":"AppInitiated","hits":42,"type":"networkActivity","domainOwner":"","bundleID":"com.example.photoeditor"}
    {"domain":"graph.facebook.com","firstTimeStamp":"2026-10-20T09:00:00Z","context":"","timeStamp":"2026-10-21T18:41:00Z","domainType":2,"initiatedType":"AppInitiated","hits":17,"type":"networkActivity","domainOwner":"Meta Platforms, Inc.","bundleID":"com.example.photoeditor"}
    {"domain":"app-measurement.com","firstTimeStamp":"2026-10-20T09:00:00Z","context":"","timeStamp":"2026-10-21T18:41:00Z","domainType":2,"initiatedType":"AppInitiated","hits":9,"type":"networkActivity","domainOwner":"Google LLC","bundleID":"com.example.photoeditor"}
    {"domain":"api.appsflyer.com","firstTimeStamp":"2026-10-19T07:00:00Z","context":"","timeStamp":"2026-10-21T07:01:00Z","domainType":2,"initiatedType":"AppInitiated","hits":6,"type":"networkActivity","domainOwner":"AppsFlyer Ltd.","bundleID":"com.example.weatherplus"}
    {"domain":"api.weather.example","firstTimeStamp":"2026-10-19T07:00:00Z","context":"","timeStamp":"2026-10-21T07:01:00Z","domainType":2,"initiatedType":"AppInitiated","hits":30,"type":"networkActivity","domainOwner":"","bundleID":"com.example.weatherplus"}
    {"domain":"chat.example.net","firstTimeStamp":"2026-10-21T12:00:00Z","context":"","timeStamp":"2026-10-21T12:10:00Z","domainType":2,"initiatedType":"AppInitiated","hits":120,"type":"networkActivity","domainOwner":"","bundleID":"com.example.chat"}
    """

    static var sample: PrivacyReport { (try? read(Data(sampleLines.utf8))) ?? PrivacyReport(apps: []) }
}
