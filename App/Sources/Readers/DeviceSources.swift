// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import UIKit

enum Sysctl {
    static func string(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    static func bootTime() -> Date? {
        var tv = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctlbyname("kern.boottime", &tv, &size, nil, 0) == 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(tv.tv_sec) + TimeInterval(tv.tv_usec) / 1_000_000)
    }
}

/// The window scene's screen and traits. iOS 26 deprecates `UIScreen.main`.
@MainActor
enum CurrentScene {
    static var scene: UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }
    static var traits: UITraitCollection { scene?.traitCollection ?? UITraitCollection.current }
}

// MARK: - Device identity

struct IdentitySource: SignalSource {
    var sections: [SignalSection] { [.identity] }

    func read() async -> [SignalReading] {
        let device = UIDevice.current
        var out: [SignalReading] = []
        if let idfv = device.identifierForVendor?.uuidString {
            out.append(.init(id: "idfv", value: idfv))
        }
        out.append(.init(id: "device-name", value: device.name))
        out.append(.init(id: "os-version", value: "iOS \(device.systemVersion)"))
        let build = Sysctl.string("kern.osversion") ?? "Unknown"
        out.append(.init(id: "os-build", value: build, items: [ProcessInfo.processInfo.operatingSystemVersionString]))
        let machine = Sysctl.string("hw.machine") ?? "Unknown"
        let board = Sysctl.string("hw.model")
        out.append(.init(id: "model-id", value: machine, items: board.map { ["Board: \($0)"] } ?? []))
        if let kernel = Sysctl.string("kern.version") {
            out.append(.init(id: "kernel-version", value: kernel.components(separatedBy: ":").first ?? kernel, items: [kernel]))
        }
        return out
    }
}

// MARK: - System

struct SystemSource: SignalSource {
    var sections: [SignalSection] { [.system] }

    func read() async -> [SignalReading] {
        let info = ProcessInfo.processInfo
        var out: [SignalReading] = []
        out.append(.init(id: "cpu-ram",
                         value: "\(info.processorCount) cores · \(Format.bytes(Int64(info.physicalMemory)))",
                         items: ["Active cores: \(info.activeProcessorCount)",
                                 "Memory: \(info.physicalMemory.formatted(.number)) bytes"]))
        if let boot = Sysctl.bootTime() {
            let up = Duration.seconds(info.systemUptime).formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated))
            out.append(.init(id: "boot-time", value: Format.dateTime(boot), items: ["Running for \(up)"]))
        }
        out.append(.init(id: "low-power", value: Format.onOff(info.isLowPowerModeEnabled)))

        let device = UIDevice.current
        let wasMonitoring = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        let state: String = switch device.batteryState {
        case .charging: "charging"
        case .full: "full"
        case .unplugged: "on battery"
        default: "unknown"
        }
        device.isBatteryMonitoringEnabled = wasMonitoring
        if level >= 0 {
            out.append(.init(id: "battery", value: "\(Format.percent(Double(level))), \(state)"))
        } else {
            out.append(.init(id: "battery", value: "Not available here", items: ["The Simulator has no battery."]))
        }

        let thermal: String = switch info.thermalState {
        case .nominal: "Normal"
        case .fair: "Slightly warm"
        case .serious: "Warm"
        case .critical: "Hot"
        @unknown default: "Unknown"
        }
        out.append(.init(id: "thermal", value: thermal))
        return out
    }
}

// MARK: - Storage

struct StorageSource: SignalSource {
    var sections: [SignalSection] { [.storage] }

    func read() async -> [SignalReading] {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityKey,
                                         .volumeAvailableCapacityForImportantUsageKey, .volumeCreationDateKey]
        guard let values = try? home.resourceValues(forKeys: keys) else { return [] }
        var out: [SignalReading] = []
        if let total = values.volumeTotalCapacity {
            out.append(.init(id: "disk-total", value: Format.bytes(Int64(total))))
        }
        if let free = values.volumeAvailableCapacity {
            var items: [String] = []
            if let important = values.volumeAvailableCapacityForImportantUsage {
                items.append("Free if caches were cleared: \(Format.exactBytes(important))")
            }
            out.append(.init(id: "disk-free", value: Format.exactBytes(Int64(free)), items: items))
        }
        if let created = values.volumeCreationDate {
            out.append(.init(id: "volume-created", value: Format.dateTime(created),
                             note: "Few phones were set up in this exact second."))
        }
        return out
    }
}

// MARK: - Display

struct DisplaySource: SignalSource {
    var sections: [SignalSection] { [.display] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        let traits = CurrentScene.traits
        if let screen = CurrentScene.scene?.screen {
            let px = screen.nativeBounds.size
            let zoomed = abs(screen.nativeScale - screen.scale) > 0.01
            let gamut = traits.displayGamut == .P3 ? "Wide colour (P3)" : "Standard colour (sRGB)"
            out.append(.init(id: "screen",
                             value: "\(Int(px.width)) × \(Int(px.height)) px · \(screen.maximumFramesPerSecond) Hz",
                             items: ["Scale: @\(Int(screen.scale))x (native \(Format.decimal(screen.nativeScale, digits: 2)))",
                                     "Display Zoom: \(zoomed ? "on" : "off")",
                                     gamut]))
            out.append(.init(id: "brightness", value: Format.percent(Double(screen.brightness))))
        }
        let size = traits.preferredContentSizeCategory
        let isDefault = size == .large
        out.append(.init(id: "text-size", value: Self.describe(size), items: isDefault ? ["This is the default size."] : ["Changed from the default size."]))
        return out
    }

    private static func describe(_ size: UIContentSizeCategory) -> String {
        switch size {
        case .extraSmall: "Extra small"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Default"
        case .extraLarge: "Large"
        case .extraExtraLarge: "Larger"
        case .extraExtraExtraLarge: "Largest"
        default: size.isAccessibilityCategory ? "Accessibility size" : "Custom"
        }
    }
}
