// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// hYYa Digital Footprint Check design layer: "Quiet Noir" (black ground from
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
    static let sand = InkStyle(role: .accent, color: Color(dark: 0xD2AE88, paper: 0x60411F))
    /// The footprint's own brown, for borders, separators and accent rules.
    static let sandDeep = Color(dark: 0x8F7560, paper: 0x5C4128)
    /// Card, panel and outline borders: the explain tone's blue.
    static let edge = InkStyle(role: .edge, color: Color(dark: 0x7FB2E5, paper: 0x2F4969))
    static var edgeGradient: LinearGradient { LinearGradient(colors: [edge.color.opacity(0.55), edge.color.opacity(0.15)], startPoint: .top, endPoint: .bottom) }
    static let sandSoft = Color(dark: 0xD2AE88, darkAlpha: 0.12, paper: 0x60411F, paperAlpha: 0.12)
    /// Kept as an alias so older call sites follow the accent.
    static var cyan: InkStyle { sand }
    static let blueGlow = Color(hex: 0x5B8DEF)
    static let orange = InkStyle(role: .concern, color: Color(dark: 0xEC7F6A, paper: 0x81291C))
    static let amberGlow = InkStyle(role: .amber, color: Color(dark: 0xF2C27A, paper: 0x85570F))
    static let green = InkStyle(role: .fix, color: Color(dark: 0x7CD9A8, paper: 0x135132))
    static let magenta = Color(hex: 0xE87AA8)

    // MARK: Ink
    static let ink = InkStyle(role: .text, color: Color(dark: 0xF5F5F7, paper: 0x26222B))
    static let textPrimary = ink
    static let textMuted = InkStyle(role: .muted, color: Color(dark: 0xA1A1A8, paper: 0x4A4550))
    static let textSubtle = InkStyle(role: .subtle, color: Color(dark: 0x6C6C73, paper: 0x4A464D))

    // MARK: Panels
    static let surface = Color(dark: 0x111113, paper: 0x000000, paperAlpha: 0.06)
    static let surfaceRaised = Color(dark: 0x1A1A1D, paper: 0x000000, paperAlpha: 0.08)
    static let border = Color(dark: 0xFFFFFF, darkAlpha: 0.08, paper: 0x000000, paperAlpha: 0.12)
    /// Panel edges and section rules: the footprint brown, faint.
    static let rule = InkStyle(role: .rule, color: Color(dark: 0x8F7560, darkAlpha: 0.35, paper: 0x5C4128, paperAlpha: 0.35))
    static let outline = Color(dark: 0xFFFFFF, darkAlpha: 0.18, paper: 0x000000, paperAlpha: 0.25)
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
    static let cta = Color(dark: 0xFFFFFF, paper: 0x26222B)
    static let ctaPressed = Color(dark: 0xD8D8DC, paper: 0x3A3540)
    static let ctaDepth = Color.clear
    static let onCTA = Color(dark: 0x000000, paper: 0xFFFFFF)
    static let accent = cyan
    static let iconTint = cyan
    static let glow = cyan
    static let gold = amberGlow

    static let sunflower = amberGlow
    static let sunflowerSoft = Color(dark: 0xEC7F6A, darkAlpha: 0.12, paper: 0x81291C, paperAlpha: 0.12)
    /// "Worth a look": a soft coral, distinct from the sand accent.
    static let concern = InkStyle(role: .concern, color: Color(dark: 0xEC7F6A, paper: 0x81291C))
    static let mint = green
    static let mintSoft = Color(dark: 0x7CD9A8, darkAlpha: 0.12, paper: 0x135132, paperAlpha: 0.12)
    static let calm = green
    static let lilacSoft = Color(dark: 0xFFFFFF, darkAlpha: 0.06, paper: 0x000000, paperAlpha: 0.05)

    static var blue: InkStyle { accent }
    static var amber: InkStyle { concern }

    static func color(for severity: Severity) -> InkStyle {
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
    /// A colour for the dark ground and its counterpart on a sticky note's light paper.
    /// Every paper ink is the lightest shade of its hue that reaches WCAG 2.2 AA body
    /// text contrast (4.5:1) on all six papers; measured, not guessed. Notes switch their subtree to the light scheme, so the same Brand names read
    /// as dark ink on paper and light ink on black.
    init(dark: UInt32, darkAlpha: Double = 1, paper: UInt32, paperAlpha: Double = 1) {
        func rgb(_ hex: UInt32) -> (CGFloat, CGFloat, CGFloat) {
            (CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255)
        }
        let (dr, dg, db) = rgb(dark), (pr, pg, pb) = rgb(paper)
        #if os(iOS)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .light
                ? UIColor(red: pr, green: pg, blue: pb, alpha: paperAlpha)
                : UIColor(red: dr, green: dg, blue: db, alpha: darkAlpha)
        })
        #else
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
                ? NSColor(srgbRed: pr, green: pg, blue: pb, alpha: paperAlpha)
                : NSColor(srgbRed: dr, green: dg, blue: db, alpha: darkAlpha)
        })
        #endif
    }

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
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        MascotArt()
            .frame(width: size, height: size)
            .neonGlow(Brand.cyan.color, radius: size * 0.12, intensity: scheme == .dark ? 0 : 0.45)
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
        @Environment(\.dynamicTypeSize) private var typeSize

        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                // One line normally; two at the largest text sizes, so labels never shrink too far.
                .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                .multilineTextAlignment(.center)
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
    var tint: InkStyle = Brand.ink
    @Environment(\.dynamicTypeSize) private var typeSize
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(Brand.shrinkToFitFloor)
            .foregroundStyle(tint)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .overlay(Capsule().strokeBorder(Brand.edge.opacity(0.55), lineWidth: 0.75))
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
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .rotation3DEffect(.degrees(configuration.isPressed ? 4 : 0), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.62), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

// MARK: - Navigation bar (iOS only; no-ops on the Mac, whose windows have no navigation bar)

extension View {
    @ViewBuilder func inlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder func hiddenNavigationBar() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder func clearNavigationBar() -> some View {
        #if os(iOS)
        toolbarBackground(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}

// MARK: - Haptics

#if os(iOS)
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
#else
/// Macs give feedback only on Force Touch trackpads; a light tap where it helps, nothing otherwise.
@MainActor
enum Haptics {
    private static func tap(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
    static func selection() { tap(.alignment) }
    static func success() { tap() }
    static func warning() { tap() }
    static func impact() { tap() }
    static func soft() { tap(.alignment) }
}
#endif

// MARK: - Settings links

/// The only way we open Settings. On a real iPhone with iOS 27 only two links behave
/// (docs/SETTINGS-LINKS.md): the official link to our own page, and plain `App-prefs:` to the
/// Settings home screen. Every path-style link lands on the Apps list, so none ships.
#if os(iOS)
@MainActor
enum SettingsLink {
    static func openOwnPage() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    static func openSettingsHome() {
        if let url = URL(string: "App-prefs:") { UIApplication.shared.open(url) }
    }
}
#else
/// On a Mac, System Settings panes can be opened directly with `x-apple.systempreferences:` links.
@MainActor
enum SettingsLink {
    static func openOwnPage() { openSettingsHome() }

    static func openSettingsHome() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    /// For example "com.apple.settings.PrivacySecurity.extension?Privacy_Contacts".
    static func open(pane: String) {
        if let url = URL(string: "x-apple.systempreferences:\(pane)") { NSWorkspace.shared.open(url) }
    }

    /// For areas that live in an app rather than in System Settings, such as Passwords.
    static func openApp(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { openSettingsHome(); return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
#endif

// MARK: - Small shared pieces

struct SeverityDot: View {
    let severity: Severity
    var body: some View {
        let c = Brand.color(for: severity)
        Circle()
            .fill(c)
            .frame(width: 7, height: 7)
            .neonGlow(c.color, radius: 6, intensity: severity == .high ? 0.8 : 0)
            .accessibilityLabel(severity.label)
    }
}

/// The running system's own name ("iOS", "iPadOS"), so no copy assumes which device it's on.
@MainActor enum System {
    #if os(iOS)
    static var name: String { UIDevice.current.systemName }
    static var version: String { UIDevice.current.systemVersion }
    #else
    static let name = "macOS"
    static var version: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return v.patchVersion == 0 ? "\(v.majorVersion).\(v.minorVersion)" : "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
    #endif
}

struct StatusBadge: View {
    let status: IOSStatus
    var body: some View {
        switch status {
        case .unverified:
            EmptyView()
        case .stillOpen:
            Pill(text: "Still open in \(System.name) 27", symbol: "exclamationmark.circle.fill", fg: Brand.concern, bg: Brand.sunflowerSoft)
        case .changed(let note):
            Pill(text: note, symbol: "checkmark.seal.fill", fg: Brand.green, bg: Brand.mintSoft)
        }
    }
}
