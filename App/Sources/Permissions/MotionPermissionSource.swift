// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CoreMotion
import Foundation

/// Motion & Fitness: the past week of activity, today's steps and one barometer reading.
@MainActor
final class MotionPermissionSource: SignalSource {
    let sections: [SignalSection] = [.motion]
    let permission: PermissionKind? = .motion

    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()

    func permissionState() -> PermissionState {
        guard CMMotionActivityManager.isActivityAvailable() || CMPedometer.isStepCountingAvailable() else {
            return .unavailable
        }
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized: return .granted
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        // Core Motion has no "ask" call: the first query shows the prompt, and its handler runs
        // once the person has answered.
        let now = Date()
        let start = now.addingTimeInterval(-3600)
        await PermissionWait.first(timeout: .seconds(120), fallback: ()) { once in
            if CMMotionActivityManager.isActivityAvailable() {
                activityManager.queryActivityStarting(from: start, to: now, to: queue) { _, _ in once.resume(()) }
            } else {
                pedometer.queryPedometerData(from: start, to: now) { _, _ in once.resume(()) }
            }
        }
        return permissionState()
    }

    func read() async -> [SignalReading] {
        guard permissionState() == .granted else { return [] }
        async let activity = readActivity()
        async let steps = readSteps()
        async let air = readAir()
        let results = await (activity, steps, air)
        return [results.0, results.1, results.2]
    }

    // MARK: Activity

    private func readActivity() async -> SignalReading {
        guard CMMotionActivityManager.isActivityAvailable() else {
            return SignalReading(id: "motion-activity", value: "Not available on this device")
        }
        let now = Date()
        let weekAgo = now.addingTimeInterval(-7 * 24 * 3600)
        let summary = await PermissionWait.first(timeout: .seconds(4), fallback: ActivitySummary?.none) { once in
            activityManager.queryActivityStarting(from: weekAgo, to: now, to: queue) { activities, _ in
                once.resume(activities.map { ActivitySummary($0, until: now) })
            }
        }
        guard let summary, summary.total > 0 else {
            return SignalReading(id: "motion-activity", value: "No activity history yet")
        }

        let ranked = ActivityKind.allCases
            .map { ($0, summary.seconds[$0, default: 0]) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
        let value = ranked.prefix(3)
            .map { "\($0.0.label) \(Format.percent($0.1 / summary.total))" }
            .joined(separator: ", ")

        var items = ranked.map { "\($0.0.label): \(PermissionText.duration($0.1)) over the past week" }
        if let hour = summary.busiestDrivingHour,
           let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now) {
            items.append("Most car journeys start around \(date.formatted(.dateTime.hour()))")
        }
        return SignalReading(id: "motion-activity", value: value, items: items)
    }

    // MARK: Steps

    private func readSteps() async -> SignalReading {
        guard CMPedometer.isStepCountingAvailable() else {
            return SignalReading(id: "motion-steps", value: "Not available on this device")
        }
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: now)
        let summary = await PermissionWait.first(timeout: .seconds(3), fallback: StepSummary?.none) { once in
            pedometer.queryPedometerData(from: midnight, to: now) { data, _ in
                once.resume(data.map(StepSummary.init))
            }
        }
        guard let summary else {
            return SignalReading(id: "motion-steps", value: "No step data yet")
        }
        var parts = ["\(PermissionText.count(summary.steps, "step")) today"]
        if let metres = summary.distance { parts.append(PermissionText.distance(metres: metres)) }
        var items: [String] = []
        if let up = summary.floorsUp { items.append("Floors climbed: \(up.formatted(.number))") }
        if let down = summary.floorsDown { items.append("Floors descended: \(down.formatted(.number))") }
        return SignalReading(id: "motion-steps", value: parts.joined(separator: ", "), items: items)
    }

    // MARK: Air pressure and altitude

    private func readAir() async -> SignalReading {
        var pressure: Double?
        var altitude: Double?

        if CMAltimeter.isRelativeAltitudeAvailable() {
            pressure = await PermissionWait.first(timeout: .seconds(3), fallback: Double?.none) { once in
                altimeter.startRelativeAltitudeUpdates(to: queue) { data, _ in
                    once.resume(data?.pressure.doubleValue)
                }
            }
            altimeter.stopRelativeAltitudeUpdates()
        }
        if CMAltimeter.isAbsoluteAltitudeAvailable() {
            altitude = await PermissionWait.first(timeout: .seconds(2), fallback: Double?.none) { once in
                altimeter.startAbsoluteAltitudeUpdates(to: queue) { data, _ in
                    once.resume(data?.altitude)
                }
            }
            altimeter.stopAbsoluteAltitudeUpdates()
        }

        guard pressure != nil || altitude != nil else {
            return SignalReading(id: "motion-pressure", value: "No barometer reading")
        }
        var parts: [String] = []
        if let pressure {
            // Core Motion reports kilopascals; hectopascals are what weather reports use.
            parts.append("\(Format.decimal(pressure * 10, digits: 1)) hPa")
        }
        if let altitude {
            parts.append("about \(PermissionText.distance(metres: altitude)) above sea level")
        }
        return SignalReading(id: "motion-pressure", value: parts.joined(separator: ", "))
    }
}

// MARK: - Summaries built inside Core Motion's callbacks

private enum ActivityKind: CaseIterable, Sendable {
    case still, walking, running, cycling, driving

    var label: String {
        switch self {
        case .still: "Still"
        case .walking: "Walking"
        case .running: "Running"
        case .cycling: "Cycling"
        case .driving: "In a car"
        }
    }
}

private struct ActivitySummary: Sendable {
    var seconds: [ActivityKind: TimeInterval] = [:]
    var drivingByHour: [Int: TimeInterval] = [:]

    var total: TimeInterval { seconds.values.reduce(0, +) }

    var busiestDrivingHour: Int? {
        drivingByHour.max { $0.value < $1.value }.map(\.key)
    }

    init(_ activities: [CMMotionActivity], until end: Date) {
        let calendar = Calendar.current
        for (index, activity) in activities.enumerated() {
            let next = index + 1 < activities.count ? activities[index + 1].startDate : end
            // A long silence usually means the phone was idle; don't let one entry swallow it.
            let length = min(next.timeIntervalSince(activity.startDate), 6 * 3600)
            guard length > 0, let kind = Self.kind(of: activity) else { continue }
            seconds[kind, default: 0] += length
            if kind == .driving {
                drivingByHour[calendar.component(.hour, from: activity.startDate), default: 0] += length
            }
        }
    }

    private static func kind(of activity: CMMotionActivity) -> ActivityKind? {
        if activity.automotive { return .driving }
        if activity.cycling { return .cycling }
        if activity.running { return .running }
        if activity.walking { return .walking }
        if activity.stationary { return .still }
        return nil
    }
}

private struct StepSummary: Sendable {
    var steps: Int
    var distance: Double?
    var floorsUp: Int?
    var floorsDown: Int?

    init(_ data: CMPedometerData) {
        steps = data.numberOfSteps.intValue
        distance = data.distance?.doubleValue
        floorsUp = data.floorsAscended?.intValue
        floorsDown = data.floorsDescended?.intValue
    }
}
