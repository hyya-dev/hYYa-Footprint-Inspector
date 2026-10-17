// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import UIKit

/// hYYa Footprint Inspector design layer: "Quiet Noir" (owner, 2026-10-17: black ground from
/// their reference, but "the glow is too much" and the layout must be elegant).
///
/// - Ground: pure black. Content sits in quiet near-black panels with hairline separators.
/// - Restraint: no glowing text. A faint light only on the score ring and status dots.
/// - Type does the work: large light numbers, clear titles, grey secondary text, lots of air.
/// - Primary button: white with black text. Everything else is text or a hairline outline.
/// - Colour meanings:
///   - Cyan is the app's own colour. It's taken from the glow of the mascot's fingerprint tablet.
///   - Orange means act: primary buttons and "worth a look".
///   - Green means fixed or all clear.
///   - Magenta and blue are used only as secondary glows in charts and decoration.
/// - Dark only. The look is the brand; there is no light theme.
enum Brand {
    static let shrinkToFitFloor: CGFloat = 0.25

    // MARK: Neon
    /// The accent, taken from the footprint the mascot is examining (#8F7560 in the artwork),
    /// lifted in lightness so it reads on black (about 9:1). Used for icons, active states, the
    /// score ring and accent marks.
    static let sand = Color(hex: 0xD2AE88)
    /// The footprint's own brown, for borders, separators and accent rules.
    static let sandDeep = Color(hex: 0x8F7560)
    static let sandSoft = Color(hex: 0xD2AE88, alpha: 0.12)
    /// Kept as an alias so older call sites follow the accent.
    static var cyan: Color { sand }
    static let blueGlow = Color(hex: 0x5B8DEF)
    static let orange = Color(hex: 0xEC7F6A)
    static let amberGlow = Color(hex: 0xF2C27A)
    static let green = Color(hex: 0x7CD9A8)
    static let magenta = Color(hex: 0xE87AA8)

    // MARK: Ink
    static let ink = Color(hex: 0xF5F5F7)
    static let textPrimary = ink
    static let textMuted = Color(hex: 0xA1A1A8)
    static let textSubtle = Color(hex: 0x6C6C73)

    // MARK: Panels
    static let surface = Color(hex: 0x111113)
    static let surfaceRaised = Color(hex: 0x1A1A1D)
    static let border = Color.white.opacity(0.08)
    /// Panel edges and section rules: the footprint brown, faint.
    static let rule = Color(hex: 0x8F7560, alpha: 0.35)
    static let outline = Color.white.opacity(0.18)
    static let shadow = Color.black.opacity(0.6)
    static let backdrop: [Color] = [.black, .black]

    /// A deep panel used for feature cards (fix steps, advice).
    static let heroStart = Color(hex: 0x111113)
    static let heroEnd = Color(hex: 0x111113)
    static var hero: LinearGradient {
        LinearGradient(colors: [heroStart, heroEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Roles
    /// Primary action: white with black text.
    static let cta = Color.white
    static let ctaPressed = Color(hex: 0xD8D8DC)
    static let ctaDepth = Color.clear
    static let onCTA = Color.black
    static let accent = cyan
    static let iconTint = cyan
    static let glow = cyan
    static let gold = amberGlow

    static let sunflower = amberGlow
    static let sunflowerSoft = Color(hex: 0xEC7F6A, alpha: 0.12)
    /// "Worth a look": a soft coral, distinct from the sand accent.
    static let concern = Color(hex: 0xEC7F6A)
    static let mint = green
    static let mintSoft = Color(hex: 0x7CD9A8, alpha: 0.12)
    static let calm = green
    static let lilacSoft = Color.white.opacity(0.06)

    static var blue: Color { accent }
    static var amber: Color { concern }

    static func color(for severity: Severity) -> Color {
        switch severity {
        case .high: concern
        case .medium: textMuted
        case .low: textSubtle
        }
    }

    static func fill(for severity: Severity) -> Color {
        switch severity {
        case .high: sunflowerSoft
        case .medium: lilacSoft
        case .low: surfaceRaised
        }
    }

    enum Radius {
        static let card: CGFloat = 24
        static let control: CGFloat = 16
        static let tile: CGFloat = 14
    }

    enum Space {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    static func brandUppercased(_ s: String) -> String {
        s.uppercased().replacingOccurrences(of: "HYYA", with: "hYYa")
    }

    @MainActor static func eyebrow(_ text: String) -> some View {
        Text(brandUppercased(text))
            .font(.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(sand)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

// MARK: - Glow

extension View {
    /// Two soft halos in the content's own colour: the "lit from within" look.
    /// A faint halo. Kept deliberately weak: one soft shadow at a fraction of the asked strength.
    func neonGlow(_ color: Color, radius: CGFloat = 10, intensity: Double = 0.75) -> some View {
        shadow(color: color.opacity(intensity * 0.35), radius: radius * 0.8)
    }
}

// MARK: - Theme (kept for stored preferences; the app is dark only)

enum AppTheme: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? { .dark }
    var displayName: String { rawValue.capitalized }
}

// MARK: - Surfaces

struct BrandBackground: View {
    var body: some View {
        ZStack {
            Color.black
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

extension View {
    func brandListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(BrandBackground())
    }

    /// A near-black panel with a hairline edge and a faint top highlight.
    func brandCard(padding: CGFloat = Brand.Space.lg, glow: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
        return self
            .padding(padding)
            .background(
                shape.fill(Brand.surface)

            )
            .overlay(shape.strokeBorder((glow ?? .white).opacity(glow == nil ? 0.08 : 0.35), lineWidth: 0.5))
    }

    func glassPanel(radius: CGFloat = 20) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: radius, style: .continuous))
    }
}

struct MascotEmblem: View {
    var size: CGFloat = 150
    var body: some View {
        Image("MascotCutout")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .neonGlow(Brand.cyan, radius: size * 0.12, intensity: 0.45)
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons

/// The primary button: a white capsule with black text that eases down when pressed.
struct PrimaryCTAButtonStyle: ButtonStyle {
    var fullWidth = true
    var fill: Color = Brand.cta
    var depthColor: Color = Brand.ctaDepth
    var textColor: Color = Brand.onCTA

    func makeBody(configuration: Configuration) -> some View {
        Look(configuration: configuration, fullWidth: fullWidth, fill: fill, textColor: textColor)
    }

    private struct Look: View {
        let configuration: Configuration
        let fullWidth: Bool
        let fill: Color
        let textColor: Color
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(Brand.shrinkToFitFloor)
                .foregroundStyle(textColor)
                .padding(.vertical, 15)
                .padding(.horizontal, 24)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(Capsule().fill(fill))
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.35)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
                .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
                .contentShape(Capsule())
        }
    }
}

/// A hairline outline button.
struct GhostButtonStyle: ButtonStyle {
    var tint: Color = Brand.ink
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(Brand.shrinkToFitFloor)
            .foregroundStyle(tint)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .overlay(Capsule().strokeBorder(Brand.sandDeep.opacity(0.8), lineWidth: 0.75))
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
            .contentShape(Capsule())
    }
}

/// Cards and rows that tip toward the finger and spring back.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.62), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

// MARK: - Haptics

@MainActor
enum Haptics {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6) }
}

// MARK: - Settings links

/// The only way we open Settings. On a real iPhone with iOS 27 only two links behave
/// (docs/SETTINGS-LINKS.md): the official link to our own page, and plain `App-prefs:` to the
/// Settings home screen. Every path-style link lands on the Apps list, so none ships.
@MainActor
enum SettingsLink {
    static func openOwnPage() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    static func openSettingsHome() {
        if let url = URL(string: "App-prefs:") { UIApplication.shared.open(url) }
    }
}

// MARK: - Small shared pieces

struct SeverityDot: View {
    let severity: Severity
    var body: some View {
        let c = Brand.color(for: severity)
        Circle()
            .fill(c)
            .frame(width: 7, height: 7)
            .neonGlow(c, radius: 6, intensity: severity == .high ? 0.8 : 0)
            .accessibilityLabel(severity.label)
    }
}

struct StatusBadge: View {
    let status: IOSStatus
    var body: some View {
        switch status {
        case .unverified:
            EmptyView()
        case .stillOpen:
            Pill(text: "Still open in iOS 27", symbol: "exclamationmark.circle.fill", fg: Brand.concern, bg: Brand.sunflowerSoft)
        case .changed(let note):
            Pill(text: note, symbol: "checkmark.seal.fill", fg: Brand.green, bg: Brand.mintSoft)
        }
    }
}
