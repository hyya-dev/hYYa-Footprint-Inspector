// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CoreBluetooth
import Foundation

/// Bluetooth: a short scan for nearby devices, keeping only the names they broadcast.
@MainActor
final class BluetoothPermissionSource: SignalSource {
    let sections: [SignalSection] = [.bluetooth]
    let permission: PermissionKind? = .bluetooth

    private var central: CBCentralManager?
    private let delegate = BluetoothDelegate()

    func permissionState() -> PermissionState {
        switch CBManager.authorization {
        case .allowedAlways: return .granted
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        // Creating the manager is what shows the prompt; it reports a state once answered.
        _ = await settledState(timeout: .seconds(120))
        return permissionState()
    }

    func read() async -> [SignalReading] {
        guard permissionState() == .granted else { return [] }

        let state = await settledState(timeout: .seconds(2))
        guard state == .poweredOn, let central else {
            return [SignalReading(id: "ble-nearby", value: "Bluetooth is off, so nothing nearby could be seen just now")]
        }

        delegate.reset()
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        try? await Task.sleep(for: .seconds(4))
        central.stopScan()

        let names = delegate.names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        let total = delegate.identifiers.count
        let value: String
        if total == 0 {
            value = "Nothing nearby right now"
        } else {
            value = "\(PermissionText.count(total, "device")) nearby, \(names.count.formatted(.number)) with a name"
        }
        var reading = SignalReading(id: "ble-nearby", value: value, items: names)
        if names.contains(where: PermissionText.looksLikeOwnersName) {
            reading.raisedSeverity = .high
            reading.note = "Some device names include a first name, which can tell an app who is nearby."
        }
        return [reading]
    }

    /// Makes the manager if needed and waits until it knows whether Bluetooth is usable.
    private func settledState(timeout: Duration) async -> CBManagerState {
        let manager: CBCentralManager
        if let central {
            manager = central
        } else {
            manager = CBCentralManager(delegate: delegate, queue: nil,
                                       options: [CBCentralManagerOptionShowPowerAlertKey: false])
            central = manager
        }
        if manager.state != .unknown && manager.state != .resetting { return manager.state }

        let state = await PermissionWait.first(timeout: timeout, fallback: CBManagerState.unknown) { once in
            delegate.stateChanged = { state in
                if state != .unknown && state != .resetting { once.resume(state) }
            }
        }
        delegate.stateChanged = nil
        return state
    }
}

/// Core Bluetooth calls back on the main queue because the manager is created with `queue: nil`.
@MainActor
private final class BluetoothDelegate: NSObject, CBCentralManagerDelegate {
    var stateChanged: ((CBManagerState) -> Void)?
    private(set) var names: Set<String> = []
    private(set) var identifiers: Set<UUID> = []

    func reset() {
        names = []
        identifiers = []
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        MainActor.assumeIsolated { stateChanged?(state) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advertised = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = (advertised ?? peripheral.name)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let identifier = peripheral.identifier
        MainActor.assumeIsolated {
            identifiers.insert(identifier)
            if let name, !name.isEmpty { names.insert(name) }
        }
    }
}
