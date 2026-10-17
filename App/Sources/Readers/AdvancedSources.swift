// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CryptoKit
import Security
import WebKit

// MARK: - Web fingerprint

/// Loads a blank page in an off-screen web view and reads what its JavaScript can see. Nothing is
/// fetched from the network: the page is an empty string with no base URL.
@MainActor
final class WebFingerprintSource: SignalSource {
    var sections: [SignalSection] { [.web] }

    private static let script = """
    (() => {
      const c = document.createElement('canvas'); c.width = 240; c.height = 60;
      const g = c.getContext('2d');
      g.textBaseline = 'top'; g.font = '16px -apple-system, Arial';
      g.fillStyle = '#f60'; g.fillRect(100, 1, 62, 20);
      g.fillStyle = '#069'; g.fillText('hYYa fingerprint 🕵️', 2, 15);
      g.fillStyle = 'rgba(102, 204, 0, 0.7)'; g.fillText('hYYa fingerprint 🕵️', 4, 17);
      let renderer = 'Hidden';
      try {
        const gl = document.createElement('canvas').getContext('webgl');
        const ext = gl && gl.getExtension('WEBGL_debug_renderer_info');
        if (ext) renderer = gl.getParameter(ext.UNMASKED_RENDERER_WEBGL);
        else if (gl) renderer = gl.getParameter(gl.RENDERER);
      } catch (e) {}
      return JSON.stringify({
        ua: navigator.userAgent,
        langs: navigator.languages,
        cores: navigator.hardwareConcurrency || 0,
        screen: screen.width + ' × ' + screen.height + ' @' + devicePixelRatio + 'x',
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
        canvas: c.toDataURL(),
        webgl: renderer
      });
    })()
    """

    func read() async -> [SignalReading] {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let web = WKWebView(frame: CGRect(x: 0, y: 0, width: 10, height: 10), configuration: config)
        web.loadHTMLString("<html><body></body></html>", baseURL: nil)
        try? await Task.sleep(for: .milliseconds(400))
        guard let json = try? await web.evaluateJavaScript(Self.script) as? String,
              let data = json.data(using: .utf8),
              let fields = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [.init(id: "web-fingerprint", value: "Couldn't read")]
        }
        let canvas = (fields["canvas"] as? String) ?? ""
        let hash = SHA256.hash(data: Data(canvas.utf8)).prefix(6).map { String(format: "%02x", $0) }.joined()
        let langs = (fields["langs"] as? [String])?.joined(separator: ", ") ?? "?"
        return [.init(id: "web-fingerprint", value: "Drawing signature \(hash)", items: [
            "Browser: \(fields["ua"] as? String ?? "?")",
            "Languages: \(langs)",
            "Cores: \(fields["cores"] as? Int ?? 0)",
            "Screen: \(fields["screen"] as? String ?? "?")",
            "Time zone: \(fields["tz"] as? String ?? "?")",
            "Graphics: \(fields["webgl"] as? String ?? "?")",
        ])]
    }
}

// MARK: - Remembered after deleting

/// Demonstrates the keychain technique on ourselves. We keep a list of our own install dates in
/// the keychain, which survives deleting the app, and a flag in UserDefaults, which doesn't. If
/// the flag is missing but the keychain list exists, the app was reinstalled. Nothing leaves the
/// phone; the item is `ThisDeviceOnly`, so it isn't synced or restored to another phone.
struct ReinstallSource: SignalSource {
    var sections: [SignalSection] { [.reinstall] }

    private static let service = "com.hyya.footprintinspector.install-log"
    private static let recordedKey = "installRecorded"

    func read() async -> [SignalReading] {
        var log = Self.loadLog()
        if !UserDefaults.standard.bool(forKey: Self.recordedKey) {
            log.append(Date())
            Self.saveLog(log)
            UserDefaults.standard.set(true, forKey: Self.recordedKey)
        }
        guard let first = log.first else { return [] }
        let count = log.count
        var reading = SignalReading(
            id: "reinstall-memory",
            value: count == 1 ? "Installed once on this iPhone" : "Installed \(count) times on this iPhone",
            items: log.enumerated().map { "Install \($0.offset + 1): \(Format.dateTime($0.element))" }
                + ["First seen: \(Format.dateTime(first))"],
            note: count == 1
                ? "Delete this app and install it again: it will still remember you. That's the point."
                : "You deleted this app before, and it still recognised you.")
        if count > 1 { reading.severityOverride = .high }
        return [reading]
    }

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: "dates"]
    }

    private static func loadLog() -> [Date] {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data,
              let stamps = try? JSONDecoder().decode([Double].self, from: data) else { return [] }
        return stamps.map(Date.init(timeIntervalSince1970:))
    }

    private static func saveLog(_ log: [Date]) {
        guard let data = try? JSONEncoder().encode(log.map(\.timeIntervalSince1970)) else { return }
        let update = [kSecValueData as String: data] as CFDictionary
        if SecItemUpdate(query as CFDictionary, update) == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(add as CFDictionary, nil)
        }
    }
}
