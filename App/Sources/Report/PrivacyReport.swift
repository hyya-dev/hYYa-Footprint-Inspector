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
        /// True when the app itself opened the connection; false for content inside it (an
        /// email's images, a web page), which the app's maker didn't choose.
        let byApp: Bool
        var id: String { domain }
    }

    /// What one app did, judged plainly. Only sharing with outside advertising or analytics
    /// companies is flagged; talking to its own servers, Apple, or sign-in and hosting services is
    /// how apps work and is never called out.
    enum Verdict: Int, Comparable, Sendable {
        case sharesOutside = 0, contentTrackers, usedData, crashReports, normal
        static func < (a: Verdict, b: Verdict) -> Bool { a.rawValue < b.rawValue }

        var label: String {
            switch self {
            case .sharesOutside: "Shares with ad or analytics companies"
            case .contentTrackers: "Content you opened had trackers"
            case .usedData: "Used your data, no sharing seen"
            case .crashReports: "Sends crash reports"
            case .normal: "Nothing unusual"
            }
        }
    }

    struct AppActivity: Sendable, Identifiable {
        let bundleID: String
        var uses: [DataKind: Int] = [:]
        var lastUse: Date?
        var sites: [String: Site] = [:]
        var id: String { bundleID }

        var isThisApp: Bool { bundleID == Bundle.main.bundleIdentifier }
        var name: String { isThisApp ? "hYYa Footprint Inspector (this app)" : AppNames.name(for: bundleID) }
        var sortedUses: [(DataKind, Int)] { uses.sorted { $0.key < $1.key }.map { ($0.key, $0.value) } }

        func kind(of site: Site) -> SiteKind { SiteKind.of(site.domain, app: bundleID) }

        /// Sites grouped by what they are, most telling first.
        var groups: [(SiteKind, [Site])] {
            Dictionary(grouping: sites.values) { kind(of: $0) }
                .map { ($0.key, $0.value.sorted { ($1.hits, $0.domain) < ($0.hits, $1.domain) }) }
                .sorted { $0.0 < $1.0 }
        }

        /// Outside advertising or analytics companies this app itself contacted.
        var outsideCompanies: [String] {
            let names = sites.values.filter { $0.byApp && kind(of: $0).isOutsideTracking }
                .map { SiteKind.company(for: $0.domain) ?? $0.owner ?? $0.domain }
            return Array(Set(names)).sorted()
        }

        var verdict: Verdict {
            if !outsideCompanies.isEmpty { return .sharesOutside }
            if sites.values.contains(where: { !$0.byApp && kind(of: $0).isOutsideTracking }) { return .contentTrackers }
            // Apple's own apps using the camera or photos is what they're for; not worth flagging.
            if !uses.isEmpty && !isThisApp && !bundleID.hasPrefix("com.apple.") { return .usedData }
            if sites.values.contains(where: { kind(of: $0) == .crashReports }) { return .crashReports }
            return .normal
        }
    }

    var apps: [AppActivity]
    var from: Date?
    var to: Date?

    /// Most worth a look first, then by name.
    var ranked: [AppActivity] { apps.sorted { ($0.verdict, $0.name) < ($1.verdict, $1.name) } }
    var sharing: [AppActivity] { ranked.filter { $0.verdict == .sharesOutside } }
    var appsUsingData: Int { apps.filter { !$0.uses.isEmpty && !$0.isThisApp }.count }
    var days: Int {
        guard let from, let to else { return 7 }
        return max(1, Int((to.timeIntervalSince(from) / 86_400).rounded(.up)))
    }

    enum ReadError: Error, LocalizedError {
        case notAReport
        var errorDescription: String? {
            "This doesn't look like an App Privacy Report. In Settings › Privacy & Security › App Privacy Report, tap the Share button at the top right, save it to Files, then open it here."
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
        return PrivacyReport(apps: Array(byApp.values), from: first, to: last)
    }
}

/// What a site is, in plain words. Matched by domain; anything we don't know is "Other", never
/// "suspicious": an unknown name is usually a company's own server or a content network.
enum SiteKind: Int, Comparable, Sendable, CaseIterable {
    case advertising, analytics, crashReports, publicData, ownServers, apple, cloud, other

    static func < (a: SiteKind, b: SiteKind) -> Bool { a.rawValue < b.rawValue }

    var isOutsideTracking: Bool { self == .advertising || self == .analytics }

    var title: String {
        switch self {
        case .advertising: "Advertising"
        case .analytics: "Usage tracking and marketing"
        case .crashReports: "Crash reports"
        case .publicData: "Public data services"
        case .ownServers: "Its own service"
        case .apple: "Apple"
        case .cloud: "Sign-in and hosting"
        case .other: "Other sites"
        }
    }

    var meaning: String {
        switch self {
        case .advertising: "Ad companies that show and measure ads, and build profiles to target you."
        case .analytics: "Companies that record how you use the app, so it can measure and market to you."
        case .crashReports: "Error reports when the app crashes. Usually harmless."
        case .publicData: "Free services for weather, place names, maps or time zones. They get the location they answer for, but don't track you."
        case .ownServers: "The app maker's own servers. That's how the app works."
        case .apple: "Apple's services: App Store, iCloud, purchases. Normal for every app."
        case .cloud: "Sign-in, storage and hosting services the app is built on. Normal."
        case .other: "Websites we can't name for sure, often the app's own content or images."
        }
    }

    var symbol: String {
        switch self {
        case .advertising: "megaphone"
        case .analytics: "chart.line.uptrend.xyaxis"
        case .crashReports: "ant"
        case .publicData: "cloud.sun"
        case .ownServers: "building.2"
        case .apple: "apple.logo"
        case .cloud: "cloud"
        case .other: "globe"
        }
    }

    // Suffix lists. Kept conservative: a company is listed only when that's what it does.
    static let adTable: [String: String] = [
        "doubleclick.net": "Google Ads", "googlesyndication.com": "Google Ads", "googleadservices.com": "Google Ads",
        "adservice.google.com": "Google Ads", "an.facebook.com": "Meta Ads", "applovin.com": "AppLovin", "applvn.com": "AppLovin",
        "unityads.unity3d.com": "Unity Ads", "ironsrc.com": "ironSource", "ironsrc.mobi": "ironSource", "chartboost.com": "Chartboost",
        "adcolony.com": "AdColony", "vungle.com": "Vungle", "inmobi.com": "InMobi", "criteo.com": "Criteo", "criteo.net": "Criteo",
        "taboola.com": "Taboola", "outbrain.com": "Outbrain", "moatads.com": "Moat", "adnxs.com": "Xandr", "rubiconproject.com": "Magnite",
        "pubmatic.com": "PubMatic", "smaato.net": "Smaato", "ads.tiktok.com": "TikTok Ads", "ads-api.twitter.com": "X Ads",
    ]
    static let analyticsTable: [String: String] = [
        "google-analytics.com": "Google Analytics", "app-measurement.com": "Google Analytics", "app-analytics-services.com": "Google Analytics",
        "firebaselogging-pa.googleapis.com": "Google Firebase", "googletagmanager.com": "Google Tag Manager",
        "graph.facebook.com": "Meta", "connect.facebook.net": "Meta", "adjust.com": "Adjust", "adjust.io": "Adjust",
        "appsflyer.com": "AppsFlyer", "appsflyersdk.com": "AppsFlyer", "branch.io": "Branch", "app.link": "Branch",
        "kochava.com": "Kochava", "singular.net": "Singular", "onesignal.com": "OneSignal", "amplitude.com": "Amplitude",
        "mixpanel.com": "Mixpanel", "segment.io": "Segment", "segment.com": "Segment", "braze.com": "Braze", "appboy.com": "Braze",
        "analytics.tiktok.com": "TikTok", "analytics.twitter.com": "X", "scorecardresearch.com": "Comscore", "flurry.com": "Flurry",
        "awstrack.me": "Email click tracking", "sc-analytics.appspot.com": "Snap",
    ]
    static let crashTable: [String: String] = [
        "crashlytics.com": "Crashlytics", "crashlyticsreports-pa.googleapis.com": "Crashlytics", "sentry.io": "Sentry",
        "bugsnag.com": "Bugsnag", "instabug.com": "Instabug", "newrelic.com": "New Relic", "nr-data.net": "New Relic", "datadoghq.com": "Datadog",
    ]
    /// Free public services an app asks for facts. Named so the person sees what each is for.
    static let publicTable: [String: String] = [
        "open-meteo.com": "Weather (Open-Meteo)", "openweathermap.org": "Weather (OpenWeather)", "weatherapi.com": "Weather (WeatherAPI)",
        "api.met.no": "Weather (Norwegian Met Office)", "tomorrow.io": "Weather (Tomorrow.io)",
        "nominatim.openstreetmap.org": "Place names (OpenStreetMap)", "tile.openstreetmap.org": "Maps (OpenStreetMap)",
        "openstreetmap.org": "Maps (OpenStreetMap)", "photon.komoot.io": "Place names (Photon)", "geocode.maps.co": "Place names",
        "timeapi.io": "Time zone (TimeAPI)", "worldtimeapi.org": "Time zone (WorldTimeAPI)", "timezonedb.com": "Time zone (TimeZoneDB)",
        "api.aladhan.com": "Prayer times (AlAdhan)", "ipapi.co": "Rough location from your network", "ip-api.com": "Rough location from your network",
        "ipinfo.io": "Rough location from your network", "exchangerate-api.com": "Exchange rates", "frankfurter.app": "Exchange rates",
    ]
    static let appleSuffixes = ["apple.com", "icloud.com", "mzstatic.com", "apple-cloudkit.com", "apple-dns.net", "aaplimg.com", "cdn-apple.com", "icloud-content.com", "apple-mapkit.com"]
    static let cloudSuffixes = ["googleapis.com", "gstatic.com", "googleusercontent.com", "firebaseio.com", "firebaseapp.com", "appspot.com",
                                "cloudfront.net", "amazonaws.com", "akamaihd.net", "akamaiedge.net", "akamaized.net", "edgekey.net", "edgesuite.net",
                                "fastly.net", "fastly.com", "cloudflare.com", "cloudflare.net", "azureedge.net", "azurewebsites.net", "windows.net",
                                "msftauth.net", "live.com", "supabase.co", "supabase.in", "vercel.app", "netlify.app", "herokuapp.com",
                                "digitaloceanspaces.com", "b-cdn.net", "googlevideo.com", "ytimg.com", "fbcdn.net", "whatsapp.net"]

    private static func match(_ d: String, _ suffix: String) -> Bool { d == suffix || d.hasSuffix("." + suffix) }
    private static func lookup(_ d: String, _ table: [String: String]) -> String? {
        // The most specific match wins ("nominatim.openstreetmap.org" over "openstreetmap.org").
        table.filter { match(d, $0.key) }.max { $0.key.count < $1.key.count }?.value
    }

    /// The company behind an advertising, analytics or crash site, when we know it.
    static func company(for domain: String) -> String? {
        let d = domain.lowercased()
        return lookup(d, adTable) ?? lookup(d, analyticsTable) ?? lookup(d, crashTable) ?? lookup(d, publicTable)
    }

    static func of(_ domain: String, app bundleID: String) -> SiteKind {
        let d = domain.lowercased()
        let maker = Self.maker(of: bundleID)
        // A company's own trackers aren't "outside" when the app is theirs (Google Maps → Google Analytics).
        if lookup(d, crashTable) != nil { return .crashReports }
        if lookup(d, publicTable) != nil { return .publicData }
        if let co = lookup(d, adTable) { return co.lowercased().hasPrefix(maker) && !maker.isEmpty ? .ownServers : .advertising }
        if let co = lookup(d, analyticsTable) { return co.lowercased().hasPrefix(maker) && !maker.isEmpty ? .ownServers : .analytics }
        if appleSuffixes.contains(where: { match(d, $0) }) { return bundleID.hasPrefix("com.apple.") ? .ownServers : .apple }
        if !maker.isEmpty, d.split(separator: ".").contains(where: { $0.lowercased() == maker }) { return .ownServers }
        if cloudSuffixes.contains(where: { match(d, $0) }) { return maker == "google" ? .ownServers : .cloud }
        return .other
    }

    /// The maker's word from a bundle ID: "com.hyya.notes" → "hyya", "sa.com.stcbank" → "stcbank".
    static func maker(of bundleID: String) -> String {
        let parts = bundleID.lowercased().split(separator: ".").map(String.init)
        let skip: Set<String> = ["com", "net", "org", "co", "io", "sa", "ae", "uk", "de", "app", "ios", "www"]
        return parts.first { !skip.contains($0) } ?? ""
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
        // The made-up apps in the sample report (tests and store screenshots).
        "com.example.photoeditor": "Photo Editor", "com.example.weatherplus": "Weather Plus", "com.example.chat": "Chat",
        // hYYa's apps.
        "com.hyya.footprintinspector": "hYYa Footprint Inspector", "com.hyya.prayerpal": "hYYa PrayerPal", "com.hyya.encryptednotes": "hYYa Encrypted Notes",
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

    /// App Store names of the most used apps in every country, built offline by
    /// `scripts/build-app-names.mjs`. Nothing is looked up on the device.
    static let store: [String: String] = {
        guard let url = Bundle.main.url(forResource: "AppNames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return map
    }()

    /// The name we know for sure, if any.
    static func knownName(for bundleID: String) -> String? { known[bundleID] ?? store[bundleID] }

    static func name(for bundleID: String) -> String {
        if let n = knownName(for: bundleID) { return n }
        let parts = bundleID.split(separator: ".").map(String.init)
        let last = parts.reversed().first { !generic.contains($0.lowercased()) } ?? parts.last ?? bundleID
        return tidy(last)
    }

    /// For a name worked out from the ID, who made it, when the ID says: "com.stc.selfcare" → "stc".
    static func maker(ofUnnamed bundleID: String) -> String? {
        guard knownName(for: bundleID) == nil else { return nil }
        let parts = bundleID.split(separator: ".").map(String.init)
        guard parts.count >= 3, ["com", "net", "org", "co", "io", "sa", "ae"].contains(parts[0].lowercased()) || parts[0].count == 2 else { return nil }
        let org = parts[1]
        return generic.contains(org.lowercased()) || org.lowercased() == name(for: bundleID).lowercased() ? nil : org
    }

    private static func tidy(_ s: String) -> String {
        let spaced = s.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
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
