// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// A hYYa app that genuinely helps with a finding, shown after the free fix.
struct HyyaSuggestion: Sendable {
    let appName: String
    /// One honest sentence on how it helps with this finding.
    let reason: String
    let url: URL
}

/// Which hYYa app goes with which finding. **Deliberately empty**: the owner decides each pairing
/// case by case, when the time comes (CLAUDE.md). Add an entry here and the suggestion appears on
/// that finding's detail page, below the free fix. Bring back the Settings switch
/// ("Suggest hYYa apps in fixes", key `settingKey`) with the first entry; it was removed while the
/// list is empty because it did nothing.
///
/// Rules: the free fix always comes first; label it "From the makers of this app"; never suggest an
/// app that doesn't truly fix that finding; no tracking of taps.
enum HyyaSuggestions {
    static let settingKey = "showHyyaSuggestions"

    static let bySignal: [String: HyyaSuggestion] = [:]

    static func suggestion(for signalID: String) -> HyyaSuggestion? { bySignal[signalID] }
}
