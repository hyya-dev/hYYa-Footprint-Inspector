// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)

import Foundation
import MediaPlayer
import MusicKit

/// Media & Apple Music: library counts, top genres and artists, and subscription status.
@MainActor
final class MusicPermissionSource: SignalSource {
    let sections: [SignalSection] = [.music]
    let permission: PermissionKind? = .music

    func permissionState() -> PermissionState {
        switch MPMediaLibrary.authorizationStatus() {
        case .authorized: return .granted
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        await PermissionWait.first(timeout: .seconds(120), fallback: ()) { once in
            MPMediaLibrary.requestAuthorization { _ in once.resume(()) }
        }
        return permissionState()
    }

    func read() async -> [SignalReading] {
        guard permissionState() == .granted else { return [] }

        async let library = PermissionWait.offMain(timeout: .seconds(5), fallback: MusicSummary?.none, {
            MusicSummary.read(now: Date())
        })
        async let subscription = readSubscription()
        let (summary, plan) = await (library, subscription)

        var readings: [SignalReading] = []
        if let summary {
            readings.append(SignalReading(
                id: "music-library",
                value: "\(PermissionText.count(summary.songs, "song")), \(PermissionText.count(summary.albums, "album"))",
                items: [
                    "Artists: \(summary.artists.formatted(.number))",
                    "Playlists: \(summary.playlists.formatted(.number))",
                    "Added in the last 30 days: \(summary.recent.formatted(.number))",
                ]
            ))
            readings.append(SignalReading(
                id: "music-taste",
                value: summary.genres.isEmpty ? "Not enough to tell" : summary.genres.map(\.name).joined(separator: ", "),
                items: summary.genres.map { "Genre: \($0.name), \(PermissionText.count($0.count, "song"))" }
                    + summary.topArtists.map { "Artist: \($0.name), \(PermissionText.count($0.count, "song"))" }
            ))
        } else {
            readings.append(SignalReading(id: "music-library", value: "Couldn't read the library in time"))
        }
        readings.append(plan)
        return readings
    }

    private func readSubscription() async -> SignalReading {
        let plan = await PermissionWait.first(timeout: .seconds(3), fallback: MusicPlan?.none) { once in
            Task {
                let subscription = try? await MusicSubscription.current
                once.resume(subscription.map(MusicPlan.init))
            }
        }
        guard let plan else {
            return SignalReading(id: "music-sub", value: "Couldn't tell")
        }
        let value: String
        if plan.canPlayCatalogue {
            value = "Subscribed"
        } else if plan.canSubscribe {
            value = "Not subscribed"
        } else {
            value = "Not available"
        }
        return SignalReading(id: "music-sub", value: value, items: [
            "Can play the full catalogue: \(Format.yesNo(plan.canPlayCatalogue))",
            "Sync Library on: \(Format.yesNo(plan.hasCloudLibrary))",
            "Could sign up: \(Format.yesNo(plan.canSubscribe))",
        ])
    }
}

private struct MusicPlan: Sendable {
    var canPlayCatalogue: Bool
    var hasCloudLibrary: Bool
    var canSubscribe: Bool

    init(_ subscription: MusicSubscription) {
        canPlayCatalogue = subscription.canPlayCatalogContent
        hasCloudLibrary = subscription.hasCloudLibraryEnabled
        canSubscribe = subscription.canBecomeSubscriber
    }
}

/// Counts built away from the main actor.
private struct MusicSummary: Sendable {
    struct Ranked: Sendable {
        var name: String
        var count: Int
    }

    var songs = 0
    var albums = 0
    var artists = 0
    var playlists = 0
    var recent = 0
    var genres: [Ranked] = []
    var topArtists: [Ranked] = []

    static func read(now: Date) -> MusicSummary {
        var summary = MusicSummary()
        let items = MPMediaQuery.songs().items ?? []
        summary.songs = items.count
        summary.albums = MPMediaQuery.albums().collections?.count ?? 0
        summary.artists = MPMediaQuery.artists().collections?.count ?? 0
        summary.playlists = MPMediaQuery.playlists().collections?.count ?? 0

        let monthAgo = now.addingTimeInterval(-30 * 24 * 3600)
        var genres: [String: Int] = [:]
        var artists: [String: Int] = [:]
        for item in items {
            if item.dateAdded > monthAgo { summary.recent += 1 }
            if let genre = item.genre?.trimmingCharacters(in: .whitespaces), !genre.isEmpty {
                genres[genre, default: 0] += 1
            }
            if let artist = item.artist?.trimmingCharacters(in: .whitespaces), !artist.isEmpty {
                artists[artist, default: 0] += 1
            }
        }
        summary.genres = top(genres)
        summary.topArtists = top(artists)
        return summary
    }

    private static func top(_ counts: [String: Int]) -> [Ranked] {
        counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(5)
            .map { Ranked(name: $0.key, count: $0.value) }
    }
}
#endif
