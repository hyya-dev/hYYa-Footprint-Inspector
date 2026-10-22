// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)
import CoreMotion
#endif
import Observation
import SwiftUI

/// How the phone is tilted, smoothed, for the 3D parallax on the mascot and cards.
///
/// Uses the same no-permission motion APIs the app warns about, which is fitting: it's a live
/// demonstration that any app can feel how you hold your phone. Nothing is stored. Stops when
/// Reduce Motion is on or nothing is watching.
@MainActor
@Observable
final class DeviceTilt {
    static let shared = DeviceTilt()

    /// −1…1 left/right and forward/back, smoothed.
    private(set) var x: Double = 0
    private(set) var y: Double = 0

    #if os(iOS)
    private let manager = CMMotionManager()
    #endif
    private var watchers = 0
    private var baseline: (roll: Double, pitch: Double)?

    #if os(iOS)
    func start() {
        watchers += 1
        guard watchers == 1, manager.isDeviceMotionAvailable, !UIAccessibility.isReduceMotionEnabled else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let a = motion?.attitude else { return }
            if self.baseline == nil { self.baseline = (a.roll, a.pitch) }
            let b = self.baseline!
            let nx = max(-1, min(1, (a.roll - b.roll) / 0.5))
            let ny = max(-1, min(1, (a.pitch - b.pitch) / 0.5))
            self.x += (nx - self.x) * 0.15
            self.y += (ny - self.y) * 0.15
            // Let the resting angle drift so holding the phone at a new angle recentres.
            self.baseline = (b.roll + (a.roll - b.roll) * 0.01, b.pitch + (a.pitch - b.pitch) * 0.01)
        }
    }

    func stop() {
        watchers = max(0, watchers - 1)
        if watchers == 0 {
            manager.stopDeviceMotionUpdates()
            baseline = nil
            x = 0
            y = 0
        }
    }
    #else
    /// A Mac doesn't tilt, so the parallax stays still.
    func start() {}
    func stop() {}
    #endif
}

/// Tilts content in 3D with the phone.
struct TiltParallax: ViewModifier {
    var strength: Double = 8
    @State private var tilt = DeviceTilt.shared

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(tilt.x * strength), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(-tilt.y * strength * 0.6), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .onAppear { tilt.start() }
            .onDisappear { tilt.stop() }
    }
}

extension View {
    func tiltParallax(_ strength: Double = 8) -> some View { modifier(TiltParallax(strength: strength)) }

    /// Cards that rise and tip into place as they scroll in, like sheets laid on a desk.
    func scrollIn3D() -> some View {
        scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.55)
                .scaleEffect(phase.isIdentity ? 1 : 0.96)
                .rotation3DEffect(.degrees(phase.value * -10), axis: (x: 1, y: 0, z: 0), anchor: phase.value < 0 ? .bottom : .top, perspective: 0.6)
        }
    }
}
