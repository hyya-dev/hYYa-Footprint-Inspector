// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(macOS)
import Foundation

/// What the Mac scan reads, and the sections it fills, in display order.
@MainActor
enum MacSources {
    static var all: [any SignalSource] {
        [WebFingerprintSource(), ReinstallSource()]
    }

    static let sections: [SignalSection] = [
        .web, .reinstall,
        .location, .camera, .bluetooth, .localNetwork, .contacts, .photos, .calendars, .reminders,
    ]
}
#endif
