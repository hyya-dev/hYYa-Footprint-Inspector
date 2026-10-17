// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import UIKit

/// hYYa Footprint Inspector design layer. Same structure as the sibling apps (appearance-aware
/// tokens, Liquid Glass on navigation surfaces, opaque content cards), with its own colours taken
/// from the mascot: detective-blue fur, charcoal coat, the tablet's cyan glow, and amber kept
/// strictly for "worth a look". When adding a colour, derive it from the mascot.
enum Brand {
    /// How far a one-line label may shrink before it wraps or truncates (family rule).
    static let shrinkToFitFloor: CGFloat = 0.25

    /// A colour that resolves per appearance at draw time, so a theme flip can never leave a
    /// stale colour behind.
    static func dyn(_ light: Color, _ dark: Color) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }

    // MARK: Ink
    static let ink = dyn(Color(hex: 0x16203A), Color(hex: 0xEAF0FB))
    static let textPrimary = ink
    static let textMuted = dyn(Color(hex: 0x4A5571), Color(hex: 0xB4C0D8))
    static let textSubtle = dyn(Color(hex: 0x66708A), Color(hex: 0x8F9BB5))

    // MARK: Accent: detective blue
    /// Fill for primary buttons. White on it clears 5.6:1.
    static let cta = dyn(Color(hex: 0x1F5BD6), Color(hex: 0x3B7BF0))
    static let ctaPressed = dyn(Color(hex: 0x1748AB), Color(hex: 0x2F69D6))
    static let onCTA = Color.white
    /// Blue used as text and icons; clears 4.5:1 on every surface in its theme.
    static let accent = dyn(Color(hex: 0x1D55C8), Color(hex: 0x7FA8FF))
    static let iconTint = accent
    /// The tablet's glow. Highlights only, never under text.
    static let glow = dyn(Color(hex: 0x19B8C9), Color(hex: 0x4FE3F0))

    // MARK: Status
    /// "Worth a look". Readable as text in both themes.
    static let concern = dyn(Color(hex: 0xA25A00), Color(hex: 0xF6B04A))
    /// Fixed, closed, all clear.
    static let calm = dyn(Color(hex: 0x1E7A4C), Color(hex: 0x5ED39A))

    // MARK: Surfaces
    static let surface = dyn(Color(hex: 0xFFFFFF), Color(hex: 0x172036))
    static let surfaceRaised = dyn(Color(hex: 0xF6F8FC), Color(hex: 0x1D2843))
    static let border = dyn(Color(hex: 0x16203A, alpha: 0.10), Color.white.opacity(0.10))
    static let outline = dyn(Color(hex: 0x16203A, alpha: 0.35), Color.white.opacity(0.35))
    static let backdrop: [Color] = [
        dyn(Color(hex: 0xEEF3FB), Color(hex: 0x0B1222)),
        dyn(Color(hex: 0xF5F7FB), Color(hex: 0x0F1830)),
        dyn(Color(hex: 0xE6F4F7), Color(hex: 0x0B1A28)),
    ]

    // Backwards-compatible names used by Phase 2 views.
    static var blue: Color { accent }
    static var amber: Color { concern }

    static func color(for severity: Severity) -> Color {
        switch severity {
        case .high: concern
        case .medium: accent
        case .low: textSubtle
        }
    }

    enum Radius {
        static let card: CGFloat = 18
        static let control: CGFloat = 12
        static let tile: CGFloat = 28
    }

    enum Space {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    /// Uppercases section headers without ever turning "hYYa" into "HYYA".
    static func brandUppercased(_ s: String) -> String {
        s.uppercased().replacingOccurrences(of: "HYYA", with: "hYYa")
    }

    static func eyebrow(_ text: String) -> some View {
        Text(brandUppercased(text))
            .font(.caption2.weight(.heavy))
            .tracking(1.6)
            .foregroundStyle(textSubtle)
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

// MARK: - Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .auto: nil
        case .light: .light
        case .dark: .dark
        }
    }
    var displayName: String { rawValue.capitalized }
}

// MARK: - Surfaces

struct BrandBackground: View {
    var body: some View {
        LinearGradient(colors: Brand.backdrop, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

extension View {
    /// Lists and forms drawn over the brand backdrop instead of the system grey.
    func brandListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(BrandBackground())
    }

    /// An opaque content card.
    func brandCard(padding: CGFloat = Brand.Space.lg) -> some View {
        let shape = RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
        return self
            .padding(padding)
            .background(Brand.surface, in: shape)
            .overlay(shape.strokeBorder(Brand.border, lineWidth: 1))
            .shadow(color: Color(hex: 0x16203A, alpha: 0.08), radius: 12, y: 6)
    }

    /// Liquid Glass, for floating navigation-layer panels only.
    func glassPanel(radius: CGFloat = 20) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: radius, style: .continuous))
    }
}

/// The mascot artwork on a white tile with a hairline rim. The artwork has its own white
/// background, so the tile stays white in both appearances and the rim gives it its edge.
struct MascotEmblem: View {
    var size: CGFloat = 150

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
        Image("Mascot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background(Color.white)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Brand.dyn(Color(hex: 0x16203A, alpha: 0.12), Color.white.opacity(0.18)), lineWidth: 1))
            .shadow(color: Color(hex: 0x16203A, alpha: 0.18), radius: size * 0.10, y: size * 0.05)
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons

struct PrimaryCTAButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        Look(configuration: configuration, fullWidth: fullWidth)
    }

    private struct Look: View {
        let configuration: Configuration
        let fullWidth: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(Brand.shrinkToFitFloor)
                .foregroundStyle(Brand.onCTA)
                .padding(.vertical, 14)
                .padding(.horizontal, 26)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(Capsule().fill(configuration.isPressed ? Brand.ctaPressed : Brand.cta))
                .overlay(Capsule().strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1))
                .shadow(color: Brand.cta.opacity(configuration.isPressed ? 0.15 : 0.30),
                        radius: configuration.isPressed ? 4 : 10, y: configuration.isPressed ? 1 : 4)
                .compositingGroup()
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.975 : 1)
                .animation(.snappy(duration: 0.22), value: configuration.isPressed)
                .contentShape(Capsule())
        }
    }
}

struct GhostButtonStyle: ButtonStyle {
    var tint: Color = Brand.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(Brand.shrinkToFitFloor)
            .foregroundStyle(tint)
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .background(Capsule().fill(Brand.surface.opacity(configuration.isPressed ? 0.95 : 0.8)))
            .overlay(Capsule().strokeBorder(Brand.outline, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.snappy(duration: 0.22), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

// MARK: - Haptics

@MainActor
enum Haptics {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func impact() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
}

// MARK: - Settings links

/// The only way we open Settings. The official link opens our own page. Anything else is
/// unofficial (docs/SETTINGS-LINKS.md) and lands on the Settings home screen, so it's labelled
/// "Open Settings" and kept in one place in case App Review objects.
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
        Circle()
            .fill(Brand.color(for: severity))
            .frame(width: 10, height: 10)
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
            Label("Still open in iOS 27", systemImage: "exclamationmark.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.concern)
        case .changed(let note):
            Label(note, systemImage: "checkmark.seal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.calm)
        }
    }
}
