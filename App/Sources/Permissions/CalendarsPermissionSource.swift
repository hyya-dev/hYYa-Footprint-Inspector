// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import EventKit
import Foundation

/// Calendars: account names and how many events there are. Never event titles, places or guests.
@MainActor
final class CalendarsPermissionSource: SignalSource {
    let sections: [SignalSection] = [.calendars]
    let permission: PermissionKind? = .calendars

    func permissionState() -> PermissionState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: return .granted
        case .writeOnly: return .limited
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        await PermissionWait.first(timeout: .seconds(120), fallback: ()) { once in
            EKEventStore().requestFullAccessToEvents { _, _ in once.resume(()) }
        }
        return permissionState()
    }

    func read() async -> [SignalReading] {
        // Add Events Only can't read anything, which is the point of it.
        guard permissionState() == .granted else { return [] }

        guard let summary = await PermissionWait.offMain(timeout: .seconds(5), fallback: CalendarSummary?.none, {
            CalendarSummary.read(now: Date())
        }) else {
            return [SignalReading(id: "cal-accounts", value: "Couldn't read calendars in time")]
        }

        var accountItems = summary.accounts
        if !summary.calendarTypes.isEmpty {
            accountItems.append("Calendars: " + summary.calendarTypes
                .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
                .map { "\($0.value) \($0.key)" }
                .joined(separator: ", "))
        }
        var accounts = SignalReading(
            id: "cal-accounts",
            value: "\(PermissionText.count(summary.accounts.count, "account")), \(PermissionText.count(summary.calendarCount, "calendar"))",
            items: accountItems
        )
        if summary.accounts.contains(where: { $0.contains("@") }) {
            accounts.note = "At least one account is named after an email address."
        }

        var busyItems = [
            "Past 30 days: \(PermissionText.count(summary.past, "event"))",
            "Next 30 days: \(PermissionText.count(summary.upcoming, "event"))",
            "With other people invited: \(summary.withGuests.formatted(.number))",
            "With a place set: \(summary.withPlace.formatted(.number))",
        ]
        if let day = summary.busiestWeekday {
            busyItems.append("Busiest day: \(Calendar.current.weekdaySymbols[day - 1])")
        }
        let total = summary.past + summary.upcoming
        let busy = SignalReading(
            id: "cal-busy",
            value: "About \(PermissionText.count(Int((Double(total) / 60 * 7).rounded()), "event")) a week",
            items: busyItems
        )
        return [accounts, busy]
    }
}

/// Counts built away from the main actor.
private struct CalendarSummary: Sendable {
    var accounts: [String] = []
    var calendarCount = 0
    var calendarTypes: [String: Int] = [:]
    var past = 0
    var upcoming = 0
    var withGuests = 0
    var withPlace = 0
    var busiestWeekday: Int?

    static func read(now: Date) -> CalendarSummary {
        let store = EKEventStore()
        var summary = CalendarSummary()
        let calendars = store.calendars(for: .event)
        summary.calendarCount = calendars.count

        var sources: [String: (kind: String, calendars: Int)] = [:]
        for calendar in calendars {
            let kind = Self.label(calendar.type)
            summary.calendarTypes[kind, default: 0] += 1
            if let source = calendar.source {
                let title = source.title.isEmpty ? "Unnamed" : source.title
                sources[title, default: (Self.label(source.sourceType), 0)].calendars += 1
            }
        }
        summary.accounts = sources
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { "\($0.key) (\($0.value.kind)), \(PermissionText.count($0.value.calendars, "calendar"))" }

        let span: TimeInterval = 30 * 24 * 3600
        let predicate = store.predicateForEvents(withStart: now.addingTimeInterval(-span),
                                                 end: now.addingTimeInterval(span), calendars: nil)
        var weekdays: [Int: Int] = [:]
        for event in store.events(matching: predicate) {
            guard let start = event.startDate else { continue }
            if start < now { summary.past += 1 } else { summary.upcoming += 1 }
            if event.hasAttendees { summary.withGuests += 1 }
            if let place = event.location, !place.isEmpty { summary.withPlace += 1 }
            if !event.isAllDay {
                weekdays[Calendar.current.component(.weekday, from: start), default: 0] += 1
            }
        }
        summary.busiestWeekday = weekdays.max { $0.value < $1.value }?.key
        return summary
    }

    private static func label(_ type: EKCalendarType) -> String {
        switch type {
        case .local: "on this iPhone"
        case .calDAV: "CalDAV or iCloud"
        case .exchange: "Exchange"
        case .subscription: "subscribed"
        case .birthday: "birthdays"
        @unknown default: "other"
        }
    }

    private static func label(_ type: EKSourceType) -> String {
        switch type {
        case .local: "On this iPhone"
        case .exchange: "Exchange"
        case .calDAV: "CalDAV"
        case .mobileMe: "iCloud"
        case .subscribed: "Subscribed"
        case .birthdays: "Birthdays"
        @unknown default: "Other"
        }
    }
}
