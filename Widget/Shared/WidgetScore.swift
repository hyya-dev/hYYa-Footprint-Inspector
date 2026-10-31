// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// What the widget shows: the overall score and when the last check ran. Nothing else crosses
/// from the app, so no finding or app name ever sits in the shared container.
struct WidgetScore: Codable, Equatable, Sendable {
    let score: Int
    let checkedAt: Date

    #if os(macOS)
    private static let group = "8PYFWUL3ND.com.hyya.footprintinspector"
    #else
    private static let group = "group.com.hyya.footprintinspector"
    #endif

    private static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?.appending(path: "widget-score.json")
    }

    static func load() -> WidgetScore? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetScore.self, from: data)
    }

    /// `nil` clears it, so the widget goes back to "Not checked yet".
    static func save(_ value: WidgetScore?) {
        guard var url = fileURL else { return }
        guard let value, let data = try? JSONEncoder().encode(value) else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        // Readable once the device has been unlocked: the widget draws while it is locked.
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }
}
