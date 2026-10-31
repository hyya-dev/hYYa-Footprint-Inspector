// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Security

/// What the widget shows: the overall score and when the last check ran. Nothing else crosses
/// from the app, so no finding or app name is ever shared with it. Kept in a keychain item both
/// can read, which stays on this device and out of backups.
struct WidgetScore: Codable, Equatable, Sendable {
    let score: Int
    let checkedAt: Date

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "widget-score",
         kSecAttrAccessGroup as String: "8PYFWUL3ND.com.hyya.footprintinspector",
         kSecUseDataProtectionKeychain as String: true]
    }

    static func load() -> WidgetScore? {
        var item: CFTypeRef?
        let search = query.merging([kSecReturnData as String: true]) { $1 }
        guard SecItemCopyMatching(search as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(WidgetScore.self, from: data)
    }

    /// `nil` clears it, so the widget goes back to "Not checked yet".
    static func save(_ value: WidgetScore?) {
        SecItemDelete(query as CFDictionary)
        guard let value, let data = try? JSONEncoder().encode(value) else { return }
        // Readable once the device has been unlocked: the widget draws while it is locked.
        SecItemAdd(query.merging([kSecValueData as String: data,
                                  kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]) { $1 } as CFDictionary, nil)
    }
}
