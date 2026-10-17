// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CoreLocation
import Foundation

/// Location (While Using only): one position fix, shown as an app would see it.
///
/// Nothing is looked up: no place names, no maps, no network. Coordinates stay on screen.
@MainActor
final class LocationPermissionSource: SignalSource {
    let sections: [SignalSection] = [.location]
    let permission: PermissionKind? = .location

    private let manager = CLLocationManager()
    private let delegate = LocationDelegate()

    init() {
        manager.delegate = delegate
    }

    func permissionState() -> PermissionState {
        switch manager.authorizationStatus {
        case .notDetermined: return .notAsked
        case .authorizedWhenInUse, .authorizedAlways:
            return manager.accuracyAuthorization == .fullAccuracy ? .granted : .limited
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        await PermissionWait.first(timeout: .seconds(120), fallback: ()) { once in
            delegate.authorizationChanged = { status in
                if status != .notDetermined { once.resume(()) }
            }
            manager.requestWhenInUseAuthorization()
        }
        delegate.authorizationChanged = nil
        return permissionState()
    }

    func read() async -> [SignalReading] {
        let state = permissionState()
        guard state == .granted || state == .limited else { return [] }

        manager.desiredAccuracy = kCLLocationAccuracyBest
        let fresh = await PermissionWait.first(timeout: .seconds(5), fallback: LocationFix?.none) { once in
            delegate.locationArrived = { fix in once.resume(fix) }
            manager.requestLocation()
        }
        delegate.locationArrived = nil
        manager.stopUpdatingLocation()

        let precise = manager.accuracyAuthorization == .fullAccuracy
        var readings: [SignalReading] = []

        if let fix = fresh ?? manager.location.map(LocationFix.init) {
            var whereReading = SignalReading(
                id: "loc-where",
                value: String(format: "%.5f, %.5f", fix.latitude, fix.longitude),
                items: ["Accurate to within \(PermissionText.distance(metres: fix.horizontalAccuracy))",
                        "Measured \(fix.timestamp.formatted(date: .omitted, time: .shortened))"]
            )
            if !precise {
                whereReading.note = "Precise Location is off for this app, so this is only a rough area."
            }
            readings.append(whereReading)

            var height: [String] = []
            if fix.verticalAccuracy > 0 {
                height.append("\(PermissionText.distance(metres: fix.altitude)) above sea level, give or take \(PermissionText.distance(metres: fix.verticalAccuracy))")
            }
            height.append(fix.floor.map { "Floor \($0)" } ?? "Floor not known here")
            readings.append(SignalReading(id: "loc-altitude", value: height.joined(separator: ", ")))

            var motion: [String] = []
            if fix.speed >= 0 {
                motion.append(Measurement(value: fix.speed, unit: UnitSpeed.metersPerSecond)
                    .formatted(.measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(0)))))
            } else {
                motion.append("Speed not known")
            }
            if fix.course >= 0 {
                motion.append("heading \(Self.compass(fix.course))")
            }
            readings.append(SignalReading(id: "loc-speed", value: motion.joined(separator: ", ")))
        } else {
            readings.append(SignalReading(id: "loc-where", value: "No position yet. Try again outdoors or near a window."))
        }

        readings.append(SignalReading(
            id: "loc-precise",
            value: precise ? "On" : "Off",
            items: [precise ? "Apps you allow can see your exact spot." : "Apps only see an area a few kilometres wide."]
        ))
        return readings
    }

    private static func compass(_ degrees: Double) -> String {
        let names = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
        let index = Int((degrees / 45).rounded()) % names.count
        return "\(names[index]) (\(Int(degrees.rounded()))°)"
    }
}

/// The parts of a `CLLocation` we show, copied out on the delegate's thread.
private struct LocationFix: Sendable {
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double
    var altitude: Double
    var verticalAccuracy: Double
    var floor: Int?
    var speed: Double
    var course: Double
    var timestamp: Date

    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        altitude = location.altitude
        verticalAccuracy = location.verticalAccuracy
        floor = location.floor?.level
        speed = location.speed
        course = location.course
        timestamp = location.timestamp
    }
}

/// Core Location calls back on the thread that created the manager, which is the main thread.
@MainActor
private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var authorizationChanged: ((CLAuthorizationStatus) -> Void)?
    var locationArrived: ((LocationFix?) -> Void)?

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated { authorizationChanged?(status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let fix = locations.last.map(LocationFix.init)
        MainActor.assumeIsolated { locationArrived?(fix) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        MainActor.assumeIsolated { locationArrived?(nil) }
    }
}
