// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import EventKit
import Foundation

/// Reminders: list names and how many reminders are open. Never the reminders themselves.
@MainActor
final class RemindersPermissionSource: SignalSource {
    let sections: [SignalSection] = [.reminders]
    let permission: PermissionKind? = .reminders

    /// Kept alive while a fetch is running.
    private var store: EKEventStore?

    func permissionState() -> PermissionState {
        switch EKEventStore.authorizationStatus(for: .reminder) {
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
            EKEventStore().requestFullAccessToReminders { _, _ in once.resume(()) }
        }
        return permissionState()
    }

    func read() async -> [SignalReading] {
        guard permissionState() == .granted else { return [] }

        // A fresh store sees access granted since the last one was made.
        let store = EKEventStore()
        self.store = store
        defer { self.store = nil }

        let lists = store.calendars(for: .reminder)
            .map(\.title)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        let listReading = SignalReading(
            id: "rem-lists",
            value: PermissionText.count(lists.count, "list"),
            items: lists
        )

        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        let now = Date()
        let counts = await PermissionWait.first(timeout: .seconds(4), fallback: OpenCounts?.none) { once in
            store.fetchReminders(matching: predicate) { reminders in
                once.resume(reminders.map { OpenCounts($0, now: now) })
            }
        }
        let openReading: SignalReading
        if let counts {
            openReading = SignalReading(
                id: "rem-open",
                value: "\(PermissionText.count(counts.open, "open reminder")), \(counts.overdue.formatted(.number)) overdue",
                items: ["With a due date: \(counts.withDueDate.formatted(.number))"]
            )
        } else {
            openReading = SignalReading(id: "rem-open", value: "Couldn't count reminders in time")
        }
        return [listReading, openReading]
    }
}

private struct OpenCounts: Sendable {
    var open = 0
    var withDueDate = 0
    var overdue = 0

    init(_ reminders: [EKReminder], now: Date) {
        let calendar = Calendar.current
        open = reminders.count
        for reminder in reminders {
            guard let components = reminder.dueDateComponents,
                  let due = calendar.date(from: components) else { continue }
            withDueDate += 1
            if due < now { overdue += 1 }
        }
    }
}
