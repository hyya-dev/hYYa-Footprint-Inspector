// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CoreMotion
import Network
import UIKit

// MARK: - Motion sensors (no permission)

@MainActor
final class MotionSensorSource: SignalSource {
    var sections: [SignalSection] { [.motionSensors] }
    private let manager = CMMotionManager()

    func read() async -> [SignalReading] {
        guard manager.isDeviceMotionAvailable || manager.isAccelerometerAvailable else {
            return [.init(id: "motion-raw", value: "Not available here", items: ["The Simulator has no motion sensors."])]
        }
        manager.accelerometerUpdateInterval = 0.05
        manager.gyroUpdateInterval = 0.05
        manager.magnetometerUpdateInterval = 0.05
        manager.deviceMotionUpdateInterval = 0.05
        manager.startAccelerometerUpdates()
        manager.startGyroUpdates()
        manager.startMagnetometerUpdates()
        let frame: CMAttitudeReferenceFrame = CMMotionManager.availableAttitudeReferenceFrames().contains(.xMagneticNorthZVertical)
            ? .xMagneticNorthZVertical : .xArbitraryZVertical
        manager.startDeviceMotionUpdates(using: frame)
        try? await Task.sleep(for: .milliseconds(700))
        defer {
            manager.stopAccelerometerUpdates()
            manager.stopGyroUpdates()
            manager.stopMagnetometerUpdates()
            manager.stopDeviceMotionUpdates()
        }

        func xyz(_ x: Double, _ y: Double, _ z: Double) -> String {
            "x \(Format.decimal(x)) · y \(Format.decimal(y)) · z \(Format.decimal(z))"
        }
        var items: [String] = []
        if let a = manager.accelerometerData?.acceleration { items.append("Movement: \(xyz(a.x, a.y, a.z))") }
        if let g = manager.gyroData?.rotationRate { items.append("Turning: \(xyz(g.x, g.y, g.z))") }
        if let m = manager.magnetometerData?.magneticField { items.append("Magnetic field (compass): \(xyz(m.x, m.y, m.z))") }
        var out: [SignalReading] = []
        if let motion = manager.deviceMotion {
            let att = motion.attitude
            items.append("Tilt: side to side \(Format.decimal(att.roll, digits: 2)), front to back \(Format.decimal(att.pitch, digits: 2))")
            if frame == .xMagneticNorthZVertical, motion.heading >= 0 {
                out.append(.init(id: "heading", value: "\(Int(motion.heading.rounded()))° from north"))
            }
        }
        out.insert(.init(id: "motion-raw", value: items.isEmpty ? "No reading" : "\(items.count) sensors can be read", items: items), at: 0)
        return out
    }
}

// MARK: - Network

@MainActor
final class NetworkSource: SignalSource {
    var sections: [SignalSection] { [.network] }

    func read() async -> [SignalReading] {
        let path = await Self.currentPath()
        var kinds: [String] = []
        for iface in path?.availableInterfaces ?? [] {
            switch iface.type {
            case .wifi: kinds.append("Wi-Fi")
            case .cellular: kinds.append("Mobile data")
            case .wiredEthernet: kinds.append("Wired")
            default: kinds.append("Other")
            }
        }
        var items = ["Available: \(kinds.isEmpty ? "none" : kinds.joined(separator: ", "))"]
        if let path {
            items.append("Treated as costly data: \(Format.yesNo(path.isExpensive))")
            items.append("Low Data Mode: \(Format.onOff(path.isConstrained))")
        }

        let tunnels = Self.vpnInterfaces()
        let addresses = Self.addresses()
        return [
            .init(id: "connection", value: kinds.first ?? "Offline", items: items),
            .init(id: "vpn", value: tunnels.isEmpty ? "No VPN detected" : "VPN detected",
                  items: [],
                  severityOverride: tunnels.isEmpty ? .low : nil),
            .init(id: "local-ip", value: "\(addresses.count) address\(addresses.count == 1 ? "" : "es")", items: addresses),
        ]
    }

    private static func currentPath() async -> NWPath? {
        await withCheckedContinuation { (continuation: CheckedContinuation<NWPath?, Never>) in
            let monitor = NWPathMonitor()
            let once = Once()
            monitor.pathUpdateHandler = { path in
                if once.claim() { monitor.cancel(); continuation.resume(returning: path) }
            }
            monitor.start(queue: .global(qos: .userInitiated))
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if once.claim() { monitor.cancel(); continuation.resume(returning: nil) }
            }
        }
    }

    /// Tunnel interfaces listed in the system proxy settings any app can read.
    private static func vpnInterfaces() -> [String] {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = settings["__SCOPED__"] as? [String: Any] else { return [] }
        return scoped.keys.filter { key in
            ["tap", "tun", "ppp", "ipsec", "utun"].contains { key.hasPrefix($0) }
        }.sorted()
    }

    private static func addresses() -> [String] {
        var result: [String] = []
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(head) }
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let ifa = ptr.pointee
            guard let addr = ifa.ifa_addr else { continue }
            let family = addr.pointee.sa_family
            guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else { continue }
            let name = String(cString: ifa.ifa_name)
            guard name != "lo0" else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let len = socklen_t(family == UInt8(AF_INET) ? MemoryLayout<sockaddr_in>.size : MemoryLayout<sockaddr_in6>.size)
            guard getnameinfo(addr, len, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let text = String(cString: host)
            guard !text.hasPrefix("fe80") else { continue }
            let label = switch name {
            case let n where n.hasPrefix("en"): "Wi-Fi"
            case let n where n.hasPrefix("pdp_ip"): "Mobile data"
            case let n where n.hasPrefix("utun"): "Tunnel"
            default: name
            }
            result.append("\(label): \(text)")
        }
        return result
    }
}

/// Resumes a continuation exactly once across racing callbacks.
final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}
