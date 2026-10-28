// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// A reminder to scan again, weekly or monthly. It's a local notification scheduled on this
/// device: no server, nothing sent. Off unless the person turns it on in Settings.
enum ScanReminder: String, CaseIterable, Identifiable, Sendable {
    case off, weekly, monthly

    var id: String { rawValue }
    var title: String {
        switch self {
        case .off: "Off"
        case .weekly: "Every week"
        case .monthly: "Every month"
        }
    }

    static let storageKey = "scanReminder"
    static let identifier = "scan-reminder"
    static let notificationTitle = "Time for your privacy check"
    static let notificationBody = "Restart your device, then open the app: your score updates by itself."

    /// The repeating trigger at 10:00. It's anchored on the day before today, so the first
    /// reminder comes about a week (or a month) after turning it on, not later the same day.
    func trigger(from date: Date = .now, calendar: Calendar = .current) -> UNCalendarNotificationTrigger? {
        let anchor = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        var parts = DateComponents(hour: 10, minute: 0)
        switch self {
        case .off: return nil
        case .weekly: parts.weekday = calendar.component(.weekday, from: anchor)
        case .monthly: parts.day = min(calendar.component(.day, from: anchor), 28)
        }
        return UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
    }

    /// Schedules (or clears) the reminder. Returns false when the person declined notifications,
    /// so Settings can switch back to Off and say why.
    @discardableResult
    func apply() async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        guard let trigger = trigger() else { return true }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        let content = UNMutableNotificationContent()
        content.title = Self.notificationTitle
        content.body = Self.notificationBody
        content.sound = .default
        if let mascot = Self.mascotAttachment() { content.attachments = [mascot] }
        try? await center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
        return true
    }

    /// The mascot on the notification card. The system takes over the file it's given, so a fresh
    /// copy of the picture is written each time.
    private static func mascotAttachment() -> UNNotificationAttachment? {
        #if os(iOS)
        guard let data = UIImage(named: "MascotCutout")?.pngData() else { return nil }
        #else
        guard let tiff = NSImage(named: "MascotCutout")?.tiffRepresentation,
              let data = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return nil }
        #endif
        let url = FileManager.default.temporaryDirectory.appending(path: "reminder-mascot-\(UUID().uuidString).png")
        guard (try? data.write(to: url)) != nil else { return nil }
        return try? UNNotificationAttachment(identifier: "mascot", url: url)
    }
}
