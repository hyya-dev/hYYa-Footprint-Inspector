// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// One shared source per permission, so delegates and managers live as long as the app does.
@MainActor
enum PermissionSources {
    private static var cache: [PermissionKind: any SignalSource] = [:]

    static func source(for kind: PermissionKind) -> any SignalSource {
        if let existing = cache[kind] { return existing }
        let made: any SignalSource
        switch kind {
        #if os(iOS)
        case .motion: made = MotionPermissionSource()
        case .music: made = MusicPermissionSource()
        #else
        case .motion, .music: made = UnavailableSource()
        #endif
        case .location: made = LocationPermissionSource()
        case .camera: made = CameraPermissionSource()
        case .bluetooth: made = BluetoothPermissionSource()
        #if os(iOS)
        case .localNetwork: made = LocalNetworkPermissionSource()
        #else
        case .localNetwork: made = UnavailableSource()
        #endif
        case .contacts: made = ContactsPermissionSource()
        case .photos: made = PhotosPermissionSource()
        case .calendars: made = CalendarsPermissionSource()
        case .reminders: made = RemindersPermissionSource()
        }
        cache[kind] = made
        return made
    }
}
