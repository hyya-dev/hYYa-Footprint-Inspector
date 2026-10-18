// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// One calm number for how much of this iPhone's footprint is in the user's hands, out of 100.
/// Higher is better.
///
/// Honesty rules:
/// - It is NOT a claim about how unique the phone is among all phones. We have no population data,
///   and the app sends nothing anywhere to get any. The wording says "footprint", never "1 in N".
/// - Only things the user can change count. Things only Apple can fix are the same for every
///   iPhone, so they're listed separately (``onlyAppleCount``) instead of dragging the score down.
/// - The formula is simple and shown to the user (``explanation``).
struct FootprintScore: Equatable, Sendable {
    static let highWeight = 10
    static let mediumWeight = 2

    let value: Int
    /// Points the user could win back by fixing what's fixable (equals 100 − value).
    let reachable: Int
    /// Fixable findings that cost points.
    let fixableCount: Int
    /// High findings only Apple can fix. Not in the score.
    let onlyAppleCount: Int

    enum Level: Sendable {
        case light, moderate, heavy
        var title: String {
            switch self {
            case .light: "Light footprint"
            case .moderate: "Moderate footprint"
            case .heavy: "Heavy footprint"
            }
        }
    }

    var level: Level {
        switch value {
        case 75...: .light
        case 50..<75: .moderate
        default: .heavy
        }
    }

    static func isFixable(_ finding: Finding) -> Bool {
        finding.definition.fix.level != .onlyApple
    }

    static func points(for finding: Finding) -> Int {
        guard isFixable(finding) else { return 0 }
        return switch finding.severity {
        case .high: highWeight
        case .medium: mediumWeight
        case .low: 0
        }
    }

    init(findings: [Finding]) {
        var lost = 0
        var fixable = 0
        var apple = 0
        for finding in findings {
            let p = Self.points(for: finding)
            lost += p
            if p > 0 { fixable += 1 }
            if !Self.isFixable(finding) && finding.severity == .high { apple += 1 }
        }
        value = max(0, 100 - lost)
        reachable = 100 - value
        fixableCount = fixable
        onlyAppleCount = apple
    }

    static let explanation = """
    Everyone starts at 100. Each detail worth a look that you can fix takes off \(highWeight) points, and each smaller one takes off \(mediumWeight). Settings left at their ordinary default don't count.

    Things only Apple can fix aren't in the score, because they're the same on every device and nothing you do changes them. We list them separately and track Apple's progress in the privacy scoreboard.

    The score isn't a measure of how unique your device is: that would need data from other devices, and this app never sends or receives any.
    """
}
