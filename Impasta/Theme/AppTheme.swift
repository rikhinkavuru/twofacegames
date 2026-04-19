import SwiftUI

extension Color {
    // Core Palette: Sophisticated Black, White, and Soft Grays
    static let appPrimary = Color.black
    static let appSecondary = Color(hex: "F5F5F0") // Soft Off-White/Cream
    static let appBackground = Color.white
    static let appForeground = Color(hex: "1A1A1A") // Deep Charcoal
    static let appMutedForeground = Color(hex: "707070") // Medium Gray
    static let appBorder = Color(hex: "E0E0D8") // Light Sepia/Gray Border
    static let appDestructive = Color(hex: "4A4A4A") // Dark Gray for destructive (minimalist)
    static let appMuted = Color(hex: "F9F9F7") // Very Light Sepia
    
    // Subtle, Sophisticated Accents
    static let appSoftIndigo = Color(hex: "818CF8").opacity(0.8) // Muted Indigo for primary actions
    static let appSoftSage = Color(hex: "A3B18A") // Soft Sage for success/ready states
    static let appSoftRose = Color(hex: "E5989B") // Soft Rose for subtle warnings/imposter hints
    static let appSoftAmber = Color(hex: "DDB892") // Warm Amber for host/special status
    static let appSoftSlate = Color(hex: "94A3B8") // Soft Slate for secondary info
    static let appSoftLavender = Color(hex: "CDB4DB") // Soft Lavender for role reveal
    
    // New colors for updated Home Screen
    static let appCreamBackground = Color(hex: "FDFDFB")
    static let appCreamSurface = Color(hex: "F7F7F2")
    static let appDeepBlack = Color(hex: "121212")
    static let appAccentRed = Color(hex: "E63946")
    static let appMutedGray = Color(hex: "8D8D8D")
    static let appSoftShadow = Color.black.opacity(0.05)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
}

extension Font {
    static let appCaption = Font.system(size: 12, weight: .semibold)
    static let appTinyCaption = Font.system(size: 10, weight: .semibold)
    
    static func appDisplay(size: CGFloat) -> Font { .system(size: ScreenScale.font(size), weight: .semibold) }
    static func appTitle(size: CGFloat) -> Font { .system(size: ScreenScale.font(size), weight: .medium) }
    static func appBody(size: CGFloat) -> Font { .system(size: ScreenScale.font(size), weight: .regular) }
}

extension View {
    func premiumShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }

    func accentGlow(color: Color = .black) -> some View {
        self.shadow(color: color.opacity(0.1), radius: 15, x: 0, y: 0)
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

// MARK: - Scaling Utility
struct ScreenScale {
    static let baseWidth: CGFloat = 393 // iPhone 15 base width
    static let baseHeight: CGFloat = 852 // iPhone 15 base height
    
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
        return value * min(scale, 1.2) // Cap scaling for very large screens
    }
}

extension View {
    func scaledPadding(_ edges: Edge.Set = .all, _ value: CGFloat) -> some View {
        self.padding(edges, ScreenScale.width(value))
    }
    
    func scaledFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self.frame(
            width: width.map { ScreenScale.width($0) },
            height: height.map { ScreenScale.height($0) }
        )
    }
}
