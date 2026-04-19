import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

protocol AppTheme {
    var background: Color { get }
    var surface: Color { get }
    var surfaceElevated: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textOnAccent: Color { get }
    var accent: Color { get }
    var accentSecondary: Color { get }
    var border: Color { get }
    var destructive: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var imposter: Color { get }
    var civilian: Color { get }
    var host: Color { get }
}

struct LightTheme: AppTheme {
    let background = Color(hex: "F4F7FF")
    let surface = Color(hex: "FFFFFF")
    let surfaceElevated = Color(hex: "E9EEFF")
    let textPrimary = Color(hex: "0A1023")
    let textSecondary = Color(hex: "5E6789")
    let textOnAccent = Color(hex: "F8FBFF")
    let accent = Color(hex: "375BFF")
    let accentSecondary = Color(hex: "7C4DFF")
    let border = Color(hex: "C9D3FF")
    let destructive = Color(hex: "FF4D6D")
    let success = Color(hex: "12D18E")
    let warning = Color(hex: "FFB84D")
    let imposter = Color(hex: "FF4D8D")
    let civilian = Color(hex: "36D4FF")
    let host = Color(hex: "FFD166")
}

struct DarkTheme: AppTheme {
    let background = Color(hex: "050816")
    let surface = Color(hex: "0D1328")
    let surfaceElevated = Color(hex: "121A35")
    let textPrimary = Color(hex: "F5F7FF")
    let textSecondary = Color(hex: "9BA8D4")
    let textOnAccent = Color(hex: "F8FBFF")
    let accent = Color(hex: "4468FF")
    let accentSecondary = Color(hex: "9A6BFF")
    let border = Color(hex: "22315F")
    let destructive = Color(hex: "FF6B8A")
    let success = Color(hex: "1DE5A8")
    let warning = Color(hex: "FFC857")
    let imposter = Color(hex: "FF5DA2")
    let civilian = Color(hex: "52E3FF")
    let host = Color(hex: "FFE27A")
}

private enum ThemeCatalog {
    static let light = LightTheme()
    static let dark = DarkTheme()
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: any AppTheme = ThemeCatalog.light
}

extension EnvironmentValues {
    var theme: any AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

private struct ThemedModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var resolvedTheme: any AppTheme {
        colorScheme == .dark ? ThemeCatalog.dark : ThemeCatalog.light
    }

    func body(content: Content) -> some View {
        content.environment(\.theme, resolvedTheme)
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedModifier())
    }
}

extension Color {
    private static var lightTheme: LightTheme { ThemeCatalog.light }
    private static var darkTheme: DarkTheme { ThemeCatalog.dark }

    // Migration aliases for legacy views. New code should prefer @Environment(\.theme)
    // so semantic tokens come from the explicitly injected theme at the app root.
    static var appPrimary: Color { dynamic(light: lightTheme.accent, dark: darkTheme.accent) }
    static var appSecondary: Color { dynamic(light: lightTheme.surface, dark: darkTheme.surface) }
    static var appBackground: Color { dynamic(light: lightTheme.background, dark: darkTheme.background) }
    static var appForeground: Color { dynamic(light: lightTheme.textPrimary, dark: darkTheme.textPrimary) }
    static var appMutedForeground: Color { dynamic(light: lightTheme.textSecondary, dark: darkTheme.textSecondary) }
    static var appBorder: Color { dynamic(light: lightTheme.border, dark: darkTheme.border) }
    static var appDestructive: Color { dynamic(light: lightTheme.destructive, dark: darkTheme.destructive) }
    static var appMuted: Color { dynamic(light: lightTheme.surfaceElevated, dark: darkTheme.surfaceElevated) }
    static var appSoftIndigo: Color { dynamic(light: lightTheme.accentSecondary, dark: darkTheme.accentSecondary) }
    static var appSoftSage: Color { dynamic(light: lightTheme.success, dark: darkTheme.success) }
    static var appSoftRose: Color { dynamic(light: lightTheme.imposter, dark: darkTheme.imposter) }
    static var appSoftAmber: Color { dynamic(light: lightTheme.host, dark: darkTheme.host) }
    static var appSoftSlate: Color { dynamic(light: lightTheme.civilian, dark: darkTheme.civilian) }
    static var appSoftLavender: Color { dynamic(light: lightTheme.accentSecondary.opacity(0.75), dark: darkTheme.accentSecondary.opacity(0.75)) }
    static var appCreamBackground: Color { appBackground }
    static var appCreamSurface: Color { appSecondary }
    static var appDeepBlack: Color { dynamic(light: lightTheme.textPrimary, dark: darkTheme.background) }
    static var appAccentRed: Color { dynamic(light: lightTheme.imposter, dark: darkTheme.imposter) }
    static var appMutedGray: Color { appMutedForeground }
    static var appSoftShadow: Color { dynamic(light: lightTheme.textPrimary.opacity(0.10), dark: darkTheme.background.opacity(0.92)) }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Legacy aliases cannot read the injected theme environment, so they mirror the
    // active system appearance until all call sites are migrated to @Environment(\.theme).
    private static func dynamic(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(
            UIColor { traitCollection in
                UIColor(traitCollection.userInterfaceStyle == .dark ? dark : light)
            }
        )
        #else
        return light
        #endif
    }
}

extension Font {
    static let appCaption = Font.system(size: 12, weight: .semibold)
    static let appTinyCaption = Font.system(size: 10, weight: .semibold)

    static func appDisplay(size: CGFloat) -> Font { .system(size: ScreenScale.font(size), weight: .semibold) }
    static func appTitle(size: CGFloat) -> Font { .system(size: ScreenScale.font(size), weight: .medium) }
    static func appBody(size: CGFloat) -> Font { .system(size: ScreenScale.font(size), weight: .regular) }
}

private struct NeonGlowModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.95), radius: 6, x: 0, y: 0)
            .shadow(color: color.opacity(0.45), radius: 18, x: 0, y: 0)
            .shadow(color: color.opacity(0.18), radius: 30, x: 0, y: 0)
    }
}

private struct GlassEffectModifier: ViewModifier {
    @Environment(\.theme) private var theme
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.surface.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(theme.border.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func premiumShadow() -> some View {
        shadow(color: Color.appSoftShadow, radius: 18, x: 0, y: 10)
    }

    func accentGlow(color: Color = .appPrimary) -> some View {
        shadow(color: color.opacity(0.35), radius: 16, x: 0, y: 0)
    }

    func neonGlow(color: Color) -> some View {
        modifier(NeonGlowModifier(color: color))
    }

    func glassEffect() -> some View {
        modifier(GlassEffectModifier())
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension Animation {
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let elegantSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
}

struct ScreenScale {
    static let baseWidth: CGFloat = 393
    static let baseHeight: CGFloat = 852

    static var screenWidth: CGFloat {
        #if os(iOS)
        let width = UIScreen.main.bounds.width
        return width > 0 ? width : baseWidth
        #else
        return baseWidth
        #endif
    }

    static var screenHeight: CGFloat {
        #if os(iOS)
        let height = UIScreen.main.bounds.height
        return height > 0 ? height : baseHeight
        #else
        return baseHeight
        #endif
    }

    static func width(_ value: CGFloat) -> CGFloat {
        let scale = baseWidth > 0 ? screenWidth / baseWidth : 1.0
        return value * scale
    }

    static func height(_ value: CGFloat) -> CGFloat {
        let scale = baseHeight > 0 ? screenHeight / baseHeight : 1.0
        return value * scale
    }

    static func font(_ value: CGFloat) -> CGFloat {
        let scale = baseWidth > 0 ? screenWidth / baseWidth : 1.0
        return value * min(scale, 1.2)
    }
}

extension View {
    func scaledPadding(_ edges: Edge.Set = .all, _ value: CGFloat) -> some View {
        padding(edges, ScreenScale.width(value))
    }

    func scaledFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        frame(
            width: width.map { ScreenScale.width($0) },
            height: height.map { ScreenScale.height($0) }
        )
    }
}
