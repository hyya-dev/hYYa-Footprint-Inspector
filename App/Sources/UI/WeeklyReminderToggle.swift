// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

/// "Remind me every week": the same reminder as Settings › Re-scan reminder, offered where a
/// weekly restart is suggested. A local notification with the mascot on it; nothing is sent.
struct WeeklyReminderToggle: View {
    @AppStorage(ScanReminder.storageKey) private var reminder = ScanReminder.off.rawValue
    @State private var declined = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(get: { reminder != ScanReminder.off.rawValue }, set: set)) {
                Label("Remind me every week", systemImage: "bell")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.ink)
            }
            .tint(Tone.fix.tint)
            if declined {
                Text("Notifications are off for this app. Turn them on in Settings › Notifications, then try again.")
                    .font(.footnote).foregroundStyle(Brand.concern).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }

    private func set(_ on: Bool) {
        let choice: ScanReminder = on ? .weekly : .off
        reminder = choice.rawValue
        Haptics.selection()
        Task {
            if await !choice.apply() {
                reminder = ScanReminder.off.rawValue
                declined = true
            }
        }
    }
}
