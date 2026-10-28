// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)

import UIKit

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
            // An app only ever sees its own company's code, so the one we can show is hYYa's.
            out.append(.init(id: "idfv", value: idfv, items: [
                "Whose code: apps made by hYYa, the maker of this app.",
                "Every company gets its own. Gmail, Google Maps and YouTube, for example, all share Google's code, and see only that one.",
                "This app can't read any other company's code, and they can't read this one.",
            // Not in the score: nothing the person does changes what this app can see here, and the
            // score only counts what a scan can see change (owner, 2026-10-28).
            ], severityOverride: .low,
               note: "Shown here is hYYa's own code, which hYYa never collects. The risk is other companies: each reads its own code to link what you do across all its apps."))
        }
        out.append(.init(id: "device-name", value: device.name))
        out.append(.init(id: "os-version", value: "\(device.systemName) \(device.systemVersion)"))
        let build = Sysctl.string("kern.osversion") ?? "Unknown"
        out.append(.init(id: "os-build", value: build, items: [ProcessInfo.processInfo.operatingSystemVersionString]))
        let machine = Sysctl.string("hw.machine") ?? "Unknown"
        let board = Sysctl.string("hw.model")
        out.append(.init(id: "model-id", value: machine, items: board.map { ["Internal code name: \($0)"] } ?? []))
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
                         value: "\(info.processorCount) processor cores · \(Format.bytes(Int64(info.physicalMemory)))",
                         items: ["Processor cores in use: \(info.activeProcessorCount)",
                                 "Memory: \(info.physicalMemory.formatted(.number)) bytes"]))
        if let boot = Sysctl.bootTime() {
            let up = Duration.seconds(Date().timeIntervalSince(boot)).formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated))
            var restart = SignalReading(id: "boot-time", value: Format.dateTime(boot), items: ["Running for \(up)"])
            // A restart in the last week is the fix itself, so it counts as done.
            // Store screenshots show a typical device, one not restarted this week.
            if RecentRestart.isRecent(boot: boot) && !LaunchOptions.has("-sampleData") { restart.severityOverride = .low; restart.note = RecentRestart.note }
            out.append(restart)
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
                items.append("Free once the system clears temporary files: \(Format.exactBytes(important))")
            }
            out.append(.init(id: "disk-free", value: Format.exactBytes(Int64(free)), items: items))
        }
        if let created = values.volumeCreationDate {
            out.append(.init(id: "volume-created", value: Format.dateTime(created),
                             note: "Few devices were set up in this exact second."))
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
            let gamut = traits.displayGamut == .P3 ? "Wide colour range" : "Standard colour range"
            out.append(.init(id: "screen",
                             value: "\(Int(px.width)) × \(Int(px.height)) px · \(screen.maximumFramesPerSecond) refreshes a second",
                             items: ["Pixel density: \(Int(screen.scale))×",
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
#endif
