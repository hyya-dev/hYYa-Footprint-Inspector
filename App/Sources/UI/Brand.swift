// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import UIKit

/// Colours taken from the mascot: detective blue, the tablet's cyan glow, and amber kept for
/// things worth a look. Phase 3 replaces this with the full hYYa design layer.
enum Brand {
    static let blue = Color(red: 0.18, green: 0.42, blue: 0.89)
    static let glow = Color(red: 0.25, green: 0.85, blue: 0.91)
    static let amber = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let calm = Color(red: 0.30, green: 0.69, blue: 0.47)

    static func color(for severity: Severity) -> Color {
        switch severity {
        case .high: amber
        case .medium: blue
        case .low: .secondary
        }
    }
}

/// The only way we open Settings. The official link opens our own page. Anything else is
/// unofficial (docs/SETTINGS-LINKS.md) and lands on the Settings home screen, so it's labelled
/// "Open Settings" and kept in one place in case App Review objects.
@MainActor
enum SettingsLink {
    static func openOwnPage() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    static func openSettingsHome() {
        if let url = URL(string: "App-prefs:") { UIApplication.shared.open(url) }
    }
}

struct SeverityDot: View {
    let severity: Severity
    var body: some View {
        Circle()
            .fill(Brand.color(for: severity))
            .frame(width: 10, height: 10)
            .accessibilityLabel(severity.label)
    }
}

struct StatusBadge: View {
    let status: IOSStatus
    var body: some View {
        switch status {
        case .unverified:
            EmptyView()
        case .stillOpen:
            Label("Still open in iOS 27", systemImage: "exclamationmark.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.amber)
        case .changed(let note):
            Label(note, systemImage: "checkmark.seal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.calm)
        }
    }
}
