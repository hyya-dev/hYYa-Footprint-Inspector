// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import AppTrackingTransparency
import AVFoundation
import CallKit
import CoreLocation
import CoreTelephony
import LocalAuthentication
import MessageUI
import Metal
import PassKit
import StoreKit
import UIKit

// MARK: - Fonts and voices

struct FontsVoicesSource: SignalSource {
    var sections: [SignalSection] { [.fontsVoices] }

    func read() async -> [SignalReading] {
        let families = UIFont.familyNames.sorted()
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let languages = Set(voices.map(\.language)).sorted()
        let downloaded = voices.filter { $0.quality == .enhanced || $0.quality == .premium }
        var voiceItems = ["Languages with voices: \(languages.count)"]
        voiceItems += downloaded.map { "Downloaded: \($0.name) (\($0.language))" }
        return [
            .init(id: "fonts", value: "\(families.count) font families", items: families),
            .init(id: "voices", value: "\(voices.count) voices, \(downloaded.count) downloaded", items: voiceItems),
        ]
    }
}

// MARK: - Account and App Store

struct AccountSource: SignalSource {
    var sections: [SignalSection] { [.accountAndApp] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        if let storefront = await Storefront.current {
            let name = Locale.current.localizedString(forRegionCode: String(storefront.countryCode.prefix(2))) ?? storefront.countryCode
            out.append(.init(id: "storefront", value: name, items: ["Code: \(storefront.countryCode)"]))
        }
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
           let created = try? docs.resourceValues(forKeys: [.creationDateKey]).creationDate {
            out.append(.init(id: "install-date", value: Format.dateTime(created)))
        }
        if case .verified(let transaction)? = try? await AppTransaction.shared {
            out.append(.init(id: "first-download", value: Format.dateTime(transaction.originalPurchaseDate),
                             items: ["First version: \(transaction.originalAppVersion)"]))
        }
        return out
    }
}

// MARK: - Graphics and cellular

struct GraphicsSource: SignalSource {
    var sections: [SignalSection] { [.graphics] }

    func read() async -> [SignalReading] {
        var out: [SignalReading] = []
        if let gpu = MTLCreateSystemDefaultDevice() {
            let families: [(String, MTLGPUFamily)] = [("Apple 7", .apple7), ("Apple 8", .apple8), ("Apple 9", .apple9), ("Metal 3", .metal3)]
            let supported = families.filter { gpu.supportsFamily($0.1) }.map(\.0)
            out.append(.init(id: "gpu", value: gpu.name, items: [
                "Ray tracing: \(Format.yesNo(gpu.supportsRaytracing))",
                "Working memory: \(Format.bytes(Int64(gpu.recommendedMaxWorkingSetSize)))",
                "Families: \(supported.joined(separator: ", "))",
            ]))
        }
        let radios = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology ?? [:]
        let kinds = radios.values.map { tech -> String in
            if tech.contains("NR") { return "5G" }
            if tech.contains("LTE") { return "4G" }
            return "3G or older"
        }
        out.append(.init(id: "cellular", value: radios.isEmpty ? "No active plans" : "\(radios.count) active plan\(radios.count == 1 ? "" : "s")",
                         items: kinds.enumerated().map { "Plan \($0.offset + 1): \($0.element)" }))
        return out
    }
}

// MARK: - Security set-up

struct SecuritySource: SignalSource {
    var sections: [SignalSection] { [.security] }

    func read() async -> [SignalReading] {
        let context = LAContext()
        let hasPasscode = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        let biometry: String = switch context.biometryType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "No biometrics"
        }
        var passcode = SignalReading(id: "passcode", value: hasPasscode ? "Passcode set · \(biometry)" : "No passcode")
        if !hasPasscode {
            passcode.severityOverride = .high
            passcode.note = "Without a passcode, anyone holding this device can see everything on it."
        }

        let networks: [(String, PKPaymentNetwork)] = [("Visa", .visa), ("Mastercard", .masterCard), ("Amex", .amex), ("Discover", .discover), ("Maestro", .maestro), ("mada", .mada)]
        let cards = networks.filter { PKPaymentAuthorizationController.canMakePayments(usingNetworks: [$0.1]) }.map(\.0)

        let tracking: String = switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized: "Allowed for this app"
        case .denied: "Turned off"
        case .restricted: "Restricted"
        case .notDetermined: "Apps may ask"
        @unknown default: "Unknown"
        }
        let managed = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed") != nil
        let locationOn = await Task.detached { CLLocationManager.locationServicesEnabled() }.value

        return [
            passcode,
            .init(id: "apple-pay", value: PKPaymentAuthorizationController.canMakePayments() ? "Available" : "Not available",
                  items: cards.isEmpty ? ["No cards detected"] : ["Card networks: \(cards.joined(separator: ", "))"]),
            .init(id: "mail-messages", value: "Mail \(MFMailComposeViewController.canSendMail() ? "set up" : "not set up") · Texts \(MFMessageComposeViewController.canSendText() ? "yes" : "no")"),
            .init(id: "on-call", value: Format.yesNo(!CXCallObserver().calls.isEmpty)),
            .init(id: "tracking", value: tracking,
                  severityOverride: ATTrackingManager.trackingAuthorizationStatus == .denied ? .low : nil),
            .init(id: "managed", value: managed ? "Yes" : "No", severityOverride: managed ? nil : .low),
            .init(id: "location-services", value: Format.onOff(locationOn)),
        ]
    }
}
