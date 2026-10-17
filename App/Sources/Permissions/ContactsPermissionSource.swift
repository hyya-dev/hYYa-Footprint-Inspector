// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Contacts
import Foundation

/// Contacts: counts, labels and account names only. We never read or show anyone's name.
@MainActor
final class ContactsPermissionSource: SignalSource {
    let sections: [SignalSection] = [.contacts]
    let permission: PermissionKind? = .contacts

    func permissionState() -> PermissionState {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: return .granted
        case .limited: return .limited
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        await PermissionWait.first(timeout: .seconds(120), fallback: ()) { once in
            CNContactStore().requestAccess(for: .contacts) { _, _ in once.resume(()) }
        }
        return permissionState()
    }

    func read() async -> [SignalReading] {
        let state = permissionState()
        guard state == .granted || state == .limited else { return [] }

        guard let summary = await PermissionWait.offMain(timeout: .seconds(5), fallback: ContactSummary?.none, {
            ContactSummary.read()
        }) else {
            return [SignalReading(id: "contact-count", value: "Couldn't read the address book in time")]
        }

        var count = SignalReading(
            id: "contact-count",
            value: PermissionText.count(summary.people, "contact"),
            items: [
                "Phone numbers: \(summary.phones.formatted(.number))",
                "Email addresses: \(summary.emails.formatted(.number))",
                "Postal addresses: \(summary.postal.formatted(.number))",
            ]
        )
        if state == .limited {
            count.note = "You chose Limited Access, so this is only the people you picked."
        }

        let ranked = summary.labels.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
        var labels = SignalReading(
            id: "contact-labels",
            value: ranked.isEmpty ? "No labels" : ranked.prefix(3).map(\.key).joined(separator: ", "),
            items: ranked.map { "\($0.key): \($0.value.formatted(.number))" }
        )
        if summary.customLabels > 0 {
            labels.severityOverride = .high
            labels.note = "\(PermissionText.count(summary.customLabels, "label")) you typed yourself. Labels like these can hint at family and close friends."
        }

        let accounts = SignalReading(
            id: "contact-accounts",
            value: PermissionText.count(summary.accounts.count, "account"),
            items: summary.accounts
        )
        return [count, labels, accounts]
    }
}

/// Counts built away from the main actor. Holds no names, numbers or addresses.
private struct ContactSummary: Sendable {
    var people = 0
    var phones = 0
    var emails = 0
    var postal = 0
    var labels: [String: Int] = [:]
    var customLabels = 0
    var accounts: [String] = []

    static func read() -> ContactSummary? {
        let store = CNContactStore()
        var summary = ContactSummary()

        let containers = (try? store.containers(matching: nil)) ?? []
        summary.accounts = containers.map { container in
            let kind: String
            switch container.type {
            case .local: kind = "On this iPhone"
            case .exchange: kind = "Exchange"
            case .cardDAV: kind = "CardDAV"
            default: kind = "Other"
            }
            let name = container.name.isEmpty ? "Unnamed" : container.name
            return "\(name) (\(kind))"
        }

        let keys = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var seenCustom = Set<String>()
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                summary.people += 1
                summary.phones += contact.phoneNumbers.count
                summary.emails += contact.emailAddresses.count
                summary.postal += contact.postalAddresses.count
                let raw = contact.phoneNumbers.compactMap(\.label) + contact.emailAddresses.compactMap(\.label)
                for label in raw {
                    // Built-in labels look like "_$!<Mobile>!$_"; anything else was typed by hand.
                    let readable = CNLabeledValue<NSString>.localizedString(forLabel: label)
                    summary.labels[readable, default: 0] += 1
                    if !label.hasPrefix("_$!<") { seenCustom.insert(readable) }
                }
            }
        } catch {
            return nil
        }
        summary.customLabels = seenCustom.count
        return summary
    }
}
