// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(macOS)
import AppKit
import Carbon
import CoreAudio
import IOKit
import IOKit.ps
import Metal
import Network
import StoreKit
import SystemConfiguration

/// Store screenshots must never show the owner's real Mac. Launched with `-sampleData`, the
/// readers that would show a name, a permanent ID, a device name or an app list show made-up
/// values instead. Nothing else changes.
enum MacSample {
    static let on = CommandLine.arguments.contains("-sampleData")
}

// MARK: - You

struct PersonSource: SignalSource {
    var sections: [SignalSection] { [.person] }

    func read() async -> [SignalReading] {
        let full = MacSample.on ? "Alex Morgan" : NSFullUserName()
        let account = MacSample.on ? "alex" : NSUserName()
        let words = full.split(separator: " ").count
        var name = SignalReading(id: "mac-full-name", value: full.isEmpty ? "Not set" : full)
        if words < 2 {
            name.severityOverride = .medium
            name.note = "Only one name. That's already less revealing."
        }
        return [
            name,
            .init(id: "mac-account-name", value: account, items: ["Home folder: /Users/\(account)"]),
            .init(id: "mac-admin", value: Self.isAdmin ? "Administrator" : "Standard account"),
        ]
    }

    private static var isAdmin: Bool {
        var groups = [gid_t](repeating: 0, count: 64)
        let count = getgroups(Int32(groups.count), &groups)
        return count > 0 && groups.prefix(Int(count)).contains(80)
    }
}

// MARK: - This Mac

enum IORegistry {
    static func platformString(_ key: String) -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        return IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? String
    }

    /// Names of connected USB devices.
    static func usbDeviceNames() -> [String] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostDevice"), &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }
        var names: [String] = []
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            if let name = IORegistryEntryCreateCFProperty(entry, "USB Product Name" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String {
                names.append(name)
            }
        }
        return names
    }
}

struct MacIdentitySource: SignalSource {
    var sections: [SignalSection] { [.identity] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        let serial = MacSample.on ? "C02SAMPLE9XY" : IORegistry.platformString("IOPlatformSerialNumber")
        if let serial { out.append(.init(id: "mac-serial", value: serial)) }
        let uuid = MacSample.on ? "5A1F0E2C-7B3D-4C8A-9E61-0D2B4F7A9C35" : IORegistry.platformString("IOPlatformUUID")
        if let uuid { out.append(.init(id: "mac-hardware-id", value: uuid)) }

        let model = Sysctl.string("hw.model") ?? "Unknown"
        let chip = Sysctl.string("machdep.cpu.brand_string") ?? "Unknown chip"
        let memory = Format.bytes(Int64(ProcessInfo.processInfo.physicalMemory))
        out.append(.init(id: "mac-model", value: "\(chip) · \(memory)",
                         items: ["Model code: \(model)", "Processor cores: \(ProcessInfo.processInfo.processorCount)"]))

        let build = Sysctl.string("kern.osversion") ?? "?"
        out.append(.init(id: "mac-system-version", value: "macOS \(System.version)", items: ["Build: \(build)"]))

        let computer = MacSample.on ? "Alex's MacBook Pro" : (SCDynamicStoreCopyComputerName(nil, nil) as String? ?? "Unknown")
        let local = MacSample.on ? "Alexs-MacBook-Pro" : (SCDynamicStoreCopyLocalHostName(nil) as String? ?? "")
        var name = SignalReading(id: "mac-computer-name", value: computer,
                                 items: local.isEmpty ? [] : ["Name on your network: \(local).local"])
        if let first = OwnerName.find(in: computer) {
            name.note = "This name suggests the owner is called \(first). Any app can read it."
        } else {
            name.severityOverride = .low
        }
        out.append(name)

        if let gpu = MTLCreateSystemDefaultDevice() {
            out.append(.init(id: "mac-graphics", value: gpu.name,
                             items: ["Graphics memory: \(Format.bytes(Int64(gpu.recommendedMaxWorkingSetSize)))"]))
        }
        return out
    }
}

// MARK: - Since you started it

struct MacSystemSource: SignalSource {
    var sections: [SignalSection] { [.system] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        if let boot = Sysctl.bootTime() {
            let up = Duration.seconds(ProcessInfo.processInfo.systemUptime)
                .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated))
            out.append(.init(id: "mac-boot-time", value: Format.dateTime(boot), items: ["Running for \(up)"]))
        }
        if let battery = Self.battery() { out.append(battery) }
        return out
    }

    private static func battery() -> SignalReading? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in list {
            guard let d = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  let now = d[kIOPSCurrentCapacityKey] as? Int, let max = d[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
            let charging = (d[kIOPSIsChargingKey] as? Bool) == true
            return .init(id: "mac-battery", value: "\(now * 100 / max)%\(charging ? ", charging" : "")")
        }
        return .init(id: "mac-battery", value: "No battery", severityOverride: .low)
    }
}

// MARK: - Storage and drives

struct MacStorageSource: SignalSource {
    var sections: [SignalSection] { [.storage] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        let root = URL(fileURLWithPath: "/")
        let values = try? root.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
        if let total = values?.volumeTotalCapacity { out.append(.init(id: "disk-total", value: Format.bytes(Int64(total)))) }
        if let free = values?.volumeAvailableCapacity { out.append(.init(id: "disk-free", value: Format.exactBytes(Int64(free)))) }

        let names: [String]
        if MacSample.on {
            names = ["Macintosh HD", "Backup"]
        } else {
            let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey], options: [.skipHiddenVolumes]) ?? []
            names = urls.compactMap { try? $0.resourceValues(forKeys: [.volumeNameKey]).volumeName }
        }
        var drives = SignalReading(id: "mac-drives", value: "\(names.count) drive\(names.count == 1 ? "" : "s")", items: names)
        if names.count <= 1 { drives.severityOverride = .low }
        if let first = names.lazy.compactMap(OwnerName.find).first {
            drives.severityOverride = .high
            drives.note = "A drive name suggests the owner is called \(first)."
        }
        out.append(drives)
        return out
    }
}

// MARK: - Screens

@MainActor
struct MacDisplaySource: SignalSource {
    var sections: [SignalSection] { [.display] }

    func read() async -> [SignalReading] {
        let screens = NSScreen.screens
        let items = screens.map { s -> String in
            let px = s.convertRectToBacking(s.frame).size
            return "\(s.localizedName): \(Int(px.width)) × \(Int(px.height)), \(s.maximumFramesPerSecond) refreshes a second"
        }
        return [.init(id: "mac-screens", value: "\(screens.count) screen\(screens.count == 1 ? "" : "s")", items: items)]
    }
}

// MARK: - Sound and accessories

struct MacAudioSource: SignalSource {
    var sections: [SignalSection] { [.audio] }

    func read() async -> [SignalReading] {
        let names = MacSample.on ? ["MacBook Pro Speakers", "MacBook Pro Microphone", "Alex's Headphones"] : Self.audioDeviceNames()
        var audio = SignalReading(id: "mac-audio", value: "\(names.count) sound device\(names.count == 1 ? "" : "s")", items: names)
        if let first = names.lazy.compactMap(OwnerName.find).first {
            audio.severityOverride = .high
            audio.note = "This name suggests the owner is called \(first). Any app can read it."
        }
        let usb = MacSample.on ? ["USB-C Hub", "Security Key"] : IORegistry.usbDeviceNames()
        var accessories = SignalReading(id: "mac-usb", value: usb.isEmpty ? "Nothing plugged in" : "\(usb.count) connected", items: usb)
        if usb.isEmpty { accessories.severityOverride = .low }
        return [audio, accessories]
    }

    private static func audioDeviceNames() -> [String] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids.compactMap { id in
            var nameAddress = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                                         mScope: kAudioObjectPropertyScopeGlobal,
                                                         mElement: kAudioObjectPropertyElementMain)
            var name: Unmanaged<CFString>?
            var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            guard AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &name) == noErr else { return nil }
            return name?.takeRetainedValue() as String?
        }
    }
}

// MARK: - Language, region and keyboards

struct MacLanguageSource: SignalSource {
    var sections: [SignalSection] { [.language] }

    func read() async -> [SignalReading] {
        let locale = Locale.current
        let languages = Locale.preferredLanguages.map { locale.localizedString(forIdentifier: $0) ?? $0 }
        let keyboards = Self.keyboardNames()
        let region = locale.region.map { locale.localizedString(forRegionCode: $0.identifier) ?? $0.identifier } ?? "Unknown"
        let tz = TimeZone.current
        let offset = tz.secondsFromGMT() / 3600
        return [
            .init(id: "mac-languages", value: languages.joined(separator: ", "), items: languages,
                  severityOverride: languages.count <= 1 ? .low : nil),
            .init(id: "mac-input-sources", value: "\(keyboards.count) keyboard\(keyboards.count == 1 ? "" : "s")", items: keyboards,
                  severityOverride: keyboards.count <= 1 ? .low : nil),
            .init(id: "mac-region", value: region, items: [
                "Calendar: \(String(describing: locale.calendar.identifier).capitalized)",
                "Week starts on \(String(describing: locale.firstDayOfWeek).capitalized)",
                "Currency: \(locale.currency?.identifier ?? "?")",
            ]),
            .init(id: "mac-timezone", value: tz.identifier.replacingOccurrences(of: "_", with: " "),
                  items: ["GMT\(offset >= 0 ? "+" : "")\(offset)"]),
        ]
    }

    private static func keyboardNames() -> [String] {
        let filter = [kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else { return [] }
        return list.compactMap { source in
            guard let raw = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
            return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
        }
    }
}

// MARK: - Accessibility and appearance

@MainActor
struct MacAccessibilitySource: SignalSource {
    var sections: [SignalSection] { [.accessibility] }

    func read() async -> [SignalReading] {
        let ws = NSWorkspace.shared
        var on: [String] = []
        if ws.isVoiceOverEnabled { on.append("VoiceOver") }
        if ws.accessibilityDisplayShouldReduceMotion { on.append("Reduce Motion") }
        if ws.accessibilityDisplayShouldIncreaseContrast { on.append("Increase Contrast") }
        if ws.accessibilityDisplayShouldReduceTransparency { on.append("Reduce Transparency") }
        if ws.accessibilityDisplayShouldDifferentiateWithoutColor { on.append("Differentiate without colour") }
        if ws.accessibilityDisplayShouldInvertColors { on.append("Invert Colours") }
        if ws.isSwitchControlEnabled { on.append("Switch Control") }

        let global = UserDefaults.standard
        let dark = global.string(forKey: "AppleInterfaceStyle") == "Dark"
        let accents = [-1: "Graphite", 0: "Red", 1: "Orange", 2: "Yellow", 3: "Green", 4: "Blue", 5: "Purple", 6: "Pink"]
        let accent = global.object(forKey: "AppleAccentColor") == nil ? "Multicolour" : (accents[global.integer(forKey: "AppleAccentColor")] ?? "Custom")
        return [
            .init(id: "mac-accessibility", value: on.isEmpty ? "None detected" : on.joined(separator: ", "), items: on,
                  severityOverride: on.isEmpty ? .low : nil),
            .init(id: "mac-appearance", value: "\(dark ? "Dark" : "Light") mode · \(accent) accent"),
        ]
    }
}

// MARK: - Clipboard

@MainActor
struct MacClipboardSource: SignalSource {
    var sections: [SignalSection] { [.clipboard] }

    /// Reads only the counter and the kinds of data. Never the contents.
    func read() async -> [SignalReading] {
        let board = NSPasteboard.general
        let types = (board.types ?? []).map(\.rawValue)
        var kinds: [String] = []
        if types.contains(where: { $0.contains("plain-text") || $0 == "NSStringPboardType" }) { kinds.append("Text") }
        if types.contains(where: { $0.contains("url") && !$0.contains("file-url") }) { kinds.append("A link") }
        if types.contains(where: { $0.contains("file-url") }) { kinds.append("A file") }
        if types.contains(where: { $0.contains("png") || $0.contains("tiff") || $0.contains("jpeg") }) { kinds.append("An image") }
        let appSpecific = types.filter { !$0.hasPrefix("public.") && !$0.hasPrefix("NS") && !$0.hasPrefix("com.apple.") }
        if !appSpecific.isEmpty { kinds.append("Data only a particular app uses (\(appSpecific.count) kinds)") }
        return [.init(id: "mac-clipboard", value: "Copied \(board.changeCount) times since you started your Mac",
                      items: (kinds.isEmpty ? ["Nothing on it now"] : kinds) + ["None of the contents were read."])]
    }
}

// MARK: - Network

struct MacNetworkSource: SignalSource {
    var sections: [SignalSection] { [.network] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        out.append(.init(id: "mac-connection", value: await Self.connectionType()))

        let hw = MacSample.on ? ["Wi-Fi: 3c:22:fb:00:00:01", "Thunderbolt Ethernet: 3c:22:fb:00:00:02"] : Self.hardwareAddresses()
        if !hw.isEmpty {
            out.append(.init(id: "mac-hardware-addresses", value: "\(hw.count) address\(hw.count == 1 ? "" : "es")", items: hw))
        }

        var dnsItems: [String] = []
        if MacSample.on {
            dnsItems = ["Router: 192.168.1.1", "Lookup servers: 192.168.1.1", "Network name: home.example"]
        } else if let store = SCDynamicStoreCreate(nil, "FootprintInspector" as CFString, nil, nil) {
            if let v4 = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
               let router = v4["Router"] as? String { dnsItems.append("Router: \(router)") }
            if let dns = SCDynamicStoreCopyValue(store, "State:/Network/Global/DNS" as CFString) as? [String: Any] {
                if let servers = dns["ServerAddresses"] as? [String], !servers.isEmpty { dnsItems.append("Lookup servers: \(servers.joined(separator: ", "))") }
                if let domains = dns["SearchDomains"] as? [String], !domains.isEmpty { dnsItems.append("Network name: \(domains.joined(separator: ", "))") }
                if let domain = dns["DomainName"] as? String { dnsItems.append("Network name: \(domain)") }
            }
        }
        let named = dnsItems.contains { $0.hasPrefix("Network name") }
        out.append(.init(id: "mac-dns", value: named ? "Network name visible" : "Router and lookup servers", items: dnsItems,
                         severityOverride: named ? nil : .low))

        let tunnels = Self.vpnInterfaces()
        out.append(.init(id: "vpn", value: tunnels.isEmpty ? "No VPN detected" : "VPN detected",
                         severityOverride: tunnels.isEmpty ? .low : nil))
        return out
    }

    private static func connectionType() async -> String {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let once = OnceFlag()
            monitor.pathUpdateHandler = { path in
                guard once.claim() else { return }
                monitor.cancel()
                let kind = path.usesInterfaceType(.wifi) ? "Wi-Fi" : path.usesInterfaceType(.wiredEthernet) ? "Ethernet"
                    : path.usesInterfaceType(.cellular) ? "Phone hotspot" : path.status == .satisfied ? "Other" : "Offline"
                continuation.resume(returning: kind)
            }
            monitor.start(queue: .global(qos: .userInitiated))
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if once.claim() { monitor.cancel(); continuation.resume(returning: "Unknown") }
            }
        }
    }

    /// Link-layer (hardware) addresses of the built-in and wired ports.
    private static func hardwareAddresses() -> [String] {
        var names: [String: String] = [:]
        for iface in (SCNetworkInterfaceCopyAll() as? [SCNetworkInterface]) ?? [] {
            if let bsd = SCNetworkInterfaceGetBSDName(iface) as String?, let label = SCNetworkInterfaceGetLocalizedDisplayName(iface) as String? {
                names[bsd] = label
            }
        }
        var result: [String] = []
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(head) }
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            guard let addr = ptr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            let bsd = String(cString: ptr.pointee.ifa_name)
            guard bsd.hasPrefix("en"), let label = names[bsd] else { continue }
            let mac: String? = addr.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { dl in
                let len = Int(dl.pointee.sdl_alen)
                guard len == 6 else { return nil }
                let bytes = withUnsafeBytes(of: dl.pointee.sdl_data) { raw in
                    Array(raw[Int(dl.pointee.sdl_nlen)..<(Int(dl.pointee.sdl_nlen) + len)])
                }
                return bytes.map { String(format: "%02x", $0) }.joined(separator: ":")
            }
            if let mac, mac != "00:00:00:00:00:00" { result.append("\(label): \(mac)") }
        }
        return result.sorted()
    }

    private static func vpnInterfaces() -> [String] {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = settings["__SCOPED__"] as? [String: Any] else { return [] }
        return scoped.keys.filter { key in ["tap", "tun", "ppp", "ipsec", "utun"].contains { key.hasPrefix($0) } }.sorted()
    }
}

/// Resumes a continuation exactly once.
final class OnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false
    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if claimed { return false }
        claimed = true
        return true
    }
}

// MARK: - Fonts

@MainActor
struct MacFontsSource: SignalSource {
    var sections: [SignalSection] { [.fontsVoices] }

    func read() async -> [SignalReading] {
        let families = NSFontManager.shared.availableFontFamilies.sorted()
        return [.init(id: "mac-fonts", value: "\(families.count) font families", items: families)]
    }
}

// MARK: - Apps on this Mac

@MainActor
struct MacAppsSource: SignalSource {
    var sections: [SignalSection] { [.apps] }

    func read() async -> [SignalReading] {
        let installed = MacSample.on ? Self.sampleApps : Self.installedApps()
        let running = MacSample.on ? ["Finder", "Safari", "Mail", "Notes", "Music", "hYYa Footprint Inspector"]
            : NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }.compactMap(\.localizedName).sorted()
        let background = MacSample.on ? 940 : Self.processCount()
        let browser = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!)?
            .deletingPathExtension().lastPathComponent ?? "Unknown"
        return [
            .init(id: "mac-installed-apps", value: "\(installed.count) apps", items: installed),
            .init(id: "mac-running-apps", value: "\(running.count) apps open, about \(background) programs running",
                  items: running + ["And about \(background) background programs, by name"]),
            .init(id: "mac-default-browser", value: browser),
        ]
    }

    /// Apps in /Applications (and its folders) and Apple's own in /System/Applications: the same
    /// list any sandboxed app can read.
    private static func installedApps() -> [String] {
        let fm = FileManager.default
        var names: [String] = []
        for folder in ["/Applications", "/Applications/Utilities", "/System/Applications", "/System/Applications/Utilities"] {
            guard let entries = try? fm.contentsOfDirectory(atPath: folder) else { continue }
            for entry in entries {
                if entry.hasSuffix(".app") {
                    names.append(String(entry.dropLast(4)))
                } else if folder == "/Applications", let inner = try? fm.contentsOfDirectory(atPath: "\(folder)/\(entry)") {
                    names += inner.filter { $0.hasSuffix(".app") }.map { String($0.dropLast(4)) }
                }
            }
        }
        return Array(Set(names)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func processCount() -> Int {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0 else { return 0 }
        return size / MemoryLayout<kinfo_proc>.stride
    }

    private static let sampleApps = ["Calendar", "Keynote", "Mail", "Maps", "Messages", "Music", "Notes", "Numbers",
                                     "Pages", "Photos", "Preview", "Reminders", "Safari", "hYYa Footprint Inspector"]
}

// MARK: - Account and App Store

struct MacAccountSource: SignalSource {
    var sections: [SignalSection] { [.accountAndApp] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        if let storefront = await Storefront.current {
            let name = Locale.current.localizedString(forRegionCode: String(storefront.countryCode.prefix(2))) ?? storefront.countryCode
            out.append(.init(id: "storefront", value: name))
        }
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
           let created = try? support.resourceValues(forKeys: [.creationDateKey]).creationDate {
            out.append(.init(id: "install-date", value: Format.dateTime(created)))
        }
        if case .verified(let transaction)? = try? await AppTransaction.shared {
            out.append(.init(id: "first-download", value: Format.dateTime(transaction.originalPurchaseDate)))
        }
        return out
    }
}
#endif
