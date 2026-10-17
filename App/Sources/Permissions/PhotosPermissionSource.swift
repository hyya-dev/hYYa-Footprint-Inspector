// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Photos

/// Photos: library size and the places photos were taken.
///
/// Places are grouped on this iPhone into squares about 1 km wide and shown as rounded
/// coordinates. Nothing is looked up online: no place names, no maps.
@MainActor
final class PhotosPermissionSource: SignalSource {
    let sections: [SignalSection] = [.photos]
    let permission: PermissionKind? = .photos

    func permissionState() -> PermissionState {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: return .granted
        case .limited: return .limited
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        await PermissionWait.first(timeout: .seconds(120), fallback: ()) { once in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in once.resume(()) }
        }
        return permissionState()
    }

    func read() async -> [SignalReading] {
        let state = permissionState()
        guard state == .granted || state == .limited else { return [] }

        guard let summary = await PermissionWait.offMain(timeout: .seconds(5.5), fallback: PhotoSummary?.none, {
            PhotoSummary.read(budget: 4)
        }) else {
            return [SignalReading(id: "photo-library", value: "Couldn't read the library in time")]
        }
        let limitedNote = state == .limited ? "You chose Limited Access, so this covers only the photos you picked." : nil

        // Places
        var places = SignalReading(
            id: "photo-places",
            value: summary.geotagged == 0
                ? "No photos with a location"
                : "\(PermissionText.count(summary.geotagged, "photo")) with a location, in \(PermissionText.count(summary.placeCount, "place"))",
            items: summary.topPlaces.prefix(10).enumerated().map { index, place in
                "Place \(index + 1): \(PermissionText.roughCoordinate(place.latitude, place.longitude)), \(PermissionText.count(place.count, "photo"))"
            },
            note: limitedNote
        )
        if let recent = summary.recentPlace, let date = recent.latest {
            places.items.append("Most recent: \(PermissionText.roughCoordinate(recent.latitude, recent.longitude)), \(date.formatted(date: .abbreviated, time: .omitted))")
        }
        if summary.partial {
            places.items.append("Stopped after \(summary.scanned.formatted(.number)) items to keep this quick")
        }
        if summary.geotagged > 0 {
            places.severityOverride = .high
            places.note = places.note ?? "Grouped on this iPhone. Nothing was sent anywhere."
        }

        // Likely home and work
        let standouts = summary.topPlaces.prefix(2).filter { $0.count >= 3 }
        var homeWork = SignalReading(
            id: "photo-home-work",
            value: standouts.isEmpty ? "No place stands out" : (standouts.count == 1 ? "One place stands out" : "Two places stand out"),
            items: standouts.map { place in
                "\(PermissionText.roughCoordinate(place.latitude, place.longitude)), \(PermissionText.count(place.count, "photo")). \(place.pattern)"
            }
        )
        if !standouts.isEmpty {
            homeWork.severityOverride = .high
            homeWork.note = "Worked out on this iPhone from photo locations alone. Any app with full Photos access could do the same."
        }

        // Library size
        var items = [
            "Videos: \(summary.videos.formatted(.number))",
            "Your albums: \(summary.userAlbums.formatted(.number))",
            "Shared albums: \(summary.sharedAlbums.formatted(.number))",
        ]
        if summary.audio > 0 { items.append("Audio: \(summary.audio.formatted(.number))") }
        let library = SignalReading(
            id: "photo-library",
            value: "\(PermissionText.count(summary.images, "photo")), \(PermissionText.count(summary.videos, "video"))",
            items: items,
            note: limitedNote
        )
        return [places, homeWork, library]
    }
}

// MARK: - On-device clustering

private struct PhotoPlace: Sendable {
    var latitude: Double
    var longitude: Double
    var count: Int
    var latest: Date?
    var weekdayWorkingHours: Int
    var eveningsAndWeekends: Int

    /// A calm hint at what kind of place this might be, from when the photos were taken.
    var pattern: String {
        let work = Double(weekdayWorkingHours) / Double(max(count, 1))
        let home = Double(eveningsAndWeekends) / Double(max(count, 1))
        if home >= 0.6 { return "Mostly evenings and weekends, which fits a home." }
        if work >= 0.5 { return "Mostly weekday working hours, which fits a workplace." }
        return "Taken at all sorts of times."
    }
}

private struct PhotoSummary: Sendable {
    var images = 0
    var videos = 0
    var audio = 0
    var userAlbums = 0
    var sharedAlbums = 0
    var scanned = 0
    var geotagged = 0
    var partial = false
    var placeCount = 0
    var topPlaces: [PhotoPlace] = []
    var recentPlace: PhotoPlace?

    private struct Cell: Hashable {
        var lat: Int
        var lon: Int
    }

    private struct Tally {
        var latSum = 0.0
        var lonSum = 0.0
        var count = 0
        var latest: Date?
        var work = 0
        var home = 0
    }

    /// Walks the library newest first, stopping after `budget` seconds.
    static func read(budget: TimeInterval) -> PhotoSummary {
        var summary = PhotoSummary()
        summary.images = PHAsset.fetchAssets(with: .image, options: nil).count
        summary.videos = PHAsset.fetchAssets(with: .video, options: nil).count
        summary.audio = PHAsset.fetchAssets(with: .audio, options: nil).count
        summary.userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil).count
        summary.sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil).count

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: options)

        let calendar = Calendar.current
        let deadline = Date().addingTimeInterval(budget)
        // About 1 km north to south. East to west the cell is widened so it stays about 1 km.
        let step = 0.009
        var tallies: [Cell: Tally] = [:]
        var newestCell: Cell?
        var scanned = 0
        var partial = false

        assets.enumerateObjects { asset, _, stop in
            scanned += 1
            if scanned % 500 == 0, Date() > deadline {
                partial = true
                stop.pointee = true
                return
            }
            guard let location = asset.location else { return }
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            guard lat != 0 || lon != 0 else { return }

            let lonStep = step / max(cos(lat * .pi / 180), 0.01)
            let cell = Cell(lat: Int((lat / step).rounded(.down)), lon: Int((lon / lonStep).rounded(.down)))
            var tally = tallies[cell, default: Tally()]
            tally.latSum += lat
            tally.lonSum += lon
            tally.count += 1
            if let date = asset.creationDate {
                tally.latest = max(tally.latest ?? date, date)
                let hour = calendar.component(.hour, from: date)
                let weekend = calendar.isDateInWeekend(date)
                if !weekend, (9..<17).contains(hour) { tally.work += 1 }
                if weekend || hour >= 19 || hour < 7 { tally.home += 1 }
            }
            tallies[cell] = tally
            if newestCell == nil { newestCell = cell }
        }

        func place(_ tally: Tally) -> PhotoPlace {
            PhotoPlace(latitude: tally.latSum / Double(tally.count),
                       longitude: tally.lonSum / Double(tally.count),
                       count: tally.count, latest: tally.latest,
                       weekdayWorkingHours: tally.work, eveningsAndWeekends: tally.home)
        }

        summary.scanned = scanned
        summary.partial = partial
        summary.geotagged = tallies.values.reduce(0) { $0 + $1.count }
        summary.placeCount = tallies.count
        summary.topPlaces = tallies.values.sorted { $0.count > $1.count }.prefix(10).map(place)
        if let newestCell, let tally = tallies[newestCell] { summary.recentPlace = place(tally) }
        return summary
    }
}
