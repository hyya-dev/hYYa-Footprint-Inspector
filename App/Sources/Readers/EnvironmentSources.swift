// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if os(iOS)

import AVFoundation
import UIKit

// MARK: - Audio

struct AudioSource: SignalSource {
    var sections: [SignalSection] { [.audio] }

    func read() async -> [SignalReading] {
        let session = AVAudioSession.sharedInstance()
        let route = session.currentRoute
        let outputs = route.outputs.map { "\($0.portName) (\(Self.kind($0.portType)))" }
        let names = route.outputs.map(\.portName) + route.inputs.map(\.portName)
        let firstName = names.lazy.compactMap(OwnerName.find).first

        var audio = SignalReading(id: "audio-route",
                                  value: route.outputs.first?.portName ?? "None",
                                  items: outputs + route.inputs.map { "Microphone: \($0.portName)" })
        if let firstName {
            audio.severityOverride = .high
            audio.note = "This name suggests the owner is called \(firstName). Any app can read it."
        }
        return [
            audio,
            .init(id: "volume", value: Format.percent(Double(session.outputVolume))),
            .init(id: "other-audio", value: Format.yesNo(session.isOtherAudioPlaying)),
        ]
    }

    private static func kind(_ type: AVAudioSession.Port) -> String {
        switch type {
        case .builtInSpeaker: "speaker"
        case .builtInReceiver: "earpiece"
        case .headphones: "wired headphones"
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE: "Bluetooth"
        case .airPlay: "AirPlay"
        case .carAudio: "car"
        case .HDMI: "HDMI"
        case .usbAudio: "USB"
        default: "other"
        }
    }
}

/// Spots a first name in device names such as "Sam's AirPods" or "Sam’s iPhone".
enum OwnerName {
    static func find(in name: String) -> String? {
        let pattern = #/^([\p{L}][\p{L}\-]{1,20})['’]s\s/#
        guard let match = name.firstMatch(of: pattern) else { return nil }
        return String(match.1)
    }
}

// MARK: - Language, region, time

struct LanguageSource: SignalSource {
    var sections: [SignalSection] { [.language] }

    func read() async -> [SignalReading] {
        let locale = Locale.current
        let languages = Locale.preferredLanguages
        let displayNames = languages.map { locale.localizedString(forIdentifier: $0) ?? $0 }

        let keyboards = UITextInputMode.activeInputModes.compactMap(\.primaryLanguage)
        let keyboardNames = keyboards.map { code -> String in
            code == "emoji" ? "Emoji" : (locale.localizedString(forIdentifier: code) ?? code)
        }

        let region = locale.region.map { locale.localizedString(forRegionCode: $0.identifier) ?? $0.identifier } ?? "Unknown"
        let calendar = locale.calendar.identifier
        let hours = locale.hourCycle == .zeroToTwentyThree || locale.hourCycle == .oneToTwentyFour ? "24-hour" : "12-hour"
        let week = Calendar.current.weekdaySymbols[locale.firstDayOfWeek.index]
        let units: String = switch locale.measurementSystem {
        case .metric: "Metric"
        case .us: "US"
        case .uk: "UK"
        default: "Other"
        }
        var regionItems = ["Calendar: \(String(describing: calendar).capitalized)",
                           "Clock: \(hours)",
                           "Week starts on \(week)",
                           "Units: \(units)"]
        if let currency = locale.currency?.identifier { regionItems.append("Currency: \(currency)") }

        let tz = TimeZone.current
        let offset = tz.secondsFromGMT() / 3600
        return [
            .init(id: "languages", value: displayNames.joined(separator: ", "), items: displayNames,
                  severityOverride: languages.count <= 1 ? .low : nil),
            .init(id: "keyboards", value: "\(keyboards.count) keyboard\(keyboards.count == 1 ? "" : "s")", items: keyboardNames,
                  severityOverride: keyboards.filter { $0 != "emoji" }.count <= 1 ? .low : nil),
            .init(id: "region", value: region, items: regionItems),
            .init(id: "timezone", value: tz.identifier.replacingOccurrences(of: "_", with: " "),
                  items: ["GMT\(offset >= 0 ? "+" : "")\(offset)"]),
        ]
    }
}

private extension Locale.Weekday {
    var index: Int {
        switch self {
        case .sunday: 0
        case .monday: 1
        case .tuesday: 2
        case .wednesday: 3
        case .thursday: 4
        case .friday: 5
        case .saturday: 6
        @unknown default: 0
        }
    }
}

// MARK: - Accessibility and appearance

struct AccessibilitySource: SignalSource {
    var sections: [SignalSection] { [.accessibility] }

    func read() async -> [SignalReading] {
        let flags: [(String, Bool)] = [
            ("VoiceOver", UIAccessibility.isVoiceOverRunning),
            ("Switch Control", UIAccessibility.isSwitchControlRunning),
            ("AssistiveTouch", UIAccessibility.isAssistiveTouchRunning),
            ("Guided Access", UIAccessibility.isGuidedAccessEnabled),
            ("Bold Text", UIAccessibility.isBoldTextEnabled),
            ("Reduce Motion", UIAccessibility.isReduceMotionEnabled),
            ("Reduce Transparency", UIAccessibility.isReduceTransparencyEnabled),
            ("Darker colours", UIAccessibility.isDarkerSystemColorsEnabled),
            ("Greyscale", UIAccessibility.isGrayscaleEnabled),
            ("Classic Invert", UIAccessibility.isInvertColorsEnabled),
            ("Mono Audio", UIAccessibility.isMonoAudioEnabled),
            ("Speak Screen", UIAccessibility.isSpeakScreenEnabled),
            ("Speak Selection", UIAccessibility.isSpeakSelectionEnabled),
            ("Closed captions", UIAccessibility.isClosedCaptioningEnabled),
            ("Shake to Undo", UIAccessibility.isShakeToUndoEnabled),
            ("Auto-play video", UIAccessibility.isVideoAutoplayEnabled),
            ("Differentiate without colour", UIAccessibility.shouldDifferentiateWithoutColor),
            ("Button Shapes", UIAccessibility.buttonShapesEnabled),
            ("On/Off labels", UIAccessibility.isOnOffSwitchLabelsEnabled),
        ]
        let on = flags.filter(\.1).map(\.0)
        let traits = CurrentScene.traits
        let style = traits.userInterfaceStyle == .dark ? "Dark mode" : "Light mode"
        let contrast = traits.accessibilityContrast == .high ? "Increase Contrast on" : "Standard contrast"
        return [
            .init(id: "accessibility",
                  value: on.isEmpty ? "None detected" : "\(on.count) on",
                  items: flags.map { "\($0.0): \($0.1 ? "on" : "off")" }),
            .init(id: "appearance", value: style, items: [contrast]),
        ]
    }
}

// MARK: - Clipboard

struct ClipboardSource: SignalSource {
    var sections: [SignalSection] { [.clipboard] }

    func read() async -> [SignalReading] {
        let board = UIPasteboard.general
        var kinds: [String] = []
        if board.hasStrings { kinds.append("Text") }
        if board.hasURLs { kinds.append("Link") }
        if board.hasImages { kinds.append("Image") }
        if board.hasColors { kinds.append("Colour") }
        return [
            .init(id: "clip-count", value: board.changeCount.formatted(.number),
                  items: ["Every copy on this device adds one."]),
            .init(id: "clip-kinds",
                  value: kinds.isEmpty ? "Empty" : kinds.joined(separator: ", "),
                  items: ["Items: \(board.numberOfItems)", "None of the contents were read."]),
        ]
    }
}
#endif
