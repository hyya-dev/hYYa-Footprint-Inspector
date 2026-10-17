// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// Hands a value back to an awaiting caller exactly once, from whichever arrives first: the
/// framework callback or the timer. Later calls are ignored.
final class PermissionOnce<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Never>?

    init(_ continuation: CheckedContinuation<T, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: T) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}

/// Small helpers that keep every permission read inside a time limit.
enum PermissionWait {
    /// Starts some callback-based work and waits for its first answer, or `fallback` after
    /// `timeout`. `start` runs straight away on the main actor.
    @MainActor
    static func first<T: Sendable>(
        timeout: Duration,
        fallback: T,
        _ start: (PermissionOnce<T>) -> Void
    ) async -> T {
        await withCheckedContinuation { continuation in
            let once = PermissionOnce(continuation)
            start(once)
            Task {
                try? await Task.sleep(for: timeout)
                once.resume(fallback)
            }
        }
    }

    /// Runs slow, synchronous work (walking a photo library, an address book) away from the main
    /// actor, giving up after `timeout`.
    @MainActor
    static func offMain<T: Sendable>(
        timeout: Duration,
        fallback: T,
        _ work: @escaping @Sendable () -> T
    ) async -> T {
        await first(timeout: timeout, fallback: fallback) { once in
            Task.detached(priority: .userInitiated) {
                once.resume(work())
            }
        }
    }
}

enum PermissionText {
    /// True when a device name looks like it belongs to someone, such as "Sam's iPad".
    static func looksLikeOwnersName(_ name: String) -> Bool {
        let lower = name.lowercased()
        for mark in ["'s ", "\u{2019}s "] where lower.contains(mark) { return true }
        return lower.hasSuffix("'s") || lower.hasSuffix("\u{2019}s")
    }

    /// Coordinates rounded to two decimals (about 1 km), always with a dot.
    static func roughCoordinate(_ latitude: Double, _ longitude: Double) -> String {
        String(format: "%.2f, %.2f", latitude, longitude)
    }

    static func count(_ value: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(value.formatted(.number)) \(value == 1 ? singular : (plural ?? singular + "s"))"
    }

    static func distance(metres: Double) -> String {
        Measurement(value: metres, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.fractionLength(0...1))))
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? "\(Int(seconds / 60)) min"
    }
}
