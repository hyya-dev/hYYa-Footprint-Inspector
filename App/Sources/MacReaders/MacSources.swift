// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(macOS)
import Foundation

/// What the Mac scan reads, and the sections it fills, in display order.
///
/// No "What websites see": a web view in a sandboxed Mac app needs the outgoing-network
/// entitlement, and this app holds none.
@MainActor
enum MacSources {
    static var all: [any SignalSource] {
        [PersonSource(), MacIdentitySource(), MacSystemSource(), MacStorageSource(), MacDisplaySource(),
         MacAudioSource(), MacLanguageSource(), MacAccessibilitySource(), MacClipboardSource(),
         MacNetworkSource(), MacFontsSource(), MacAppsSource(), MacAccountSource(),
         ReinstallSource()]
    }

    static let sections: [SignalSection] = [
        .person, .identity, .apps, .system, .storage, .display, .audio, .language, .accessibility,
        .clipboard, .network, .fontsVoices, .accountAndApp, .reinstall,
        .location, .camera, .bluetooth, .contacts, .photos, .calendars, .reminders,
    ]
}
#endif
