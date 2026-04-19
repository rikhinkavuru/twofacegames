import SwiftUI

// MARK: - Pill Button
struct PillButton: View {
    let title: String
    var icon: String? = nil
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil
    var style: PillButtonStyle = .primary
    var isDisabled: Bool = false
    var action: () -> Void

    enum PillButtonStyle {
        case primary
        case secondary
        case destructive
        case subtle // New: subtle color accent
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .appPrimary
        case .secondary: return .appSecondary
        case .destructive: return .appDestructive.opacity(0.1)
        case .subtle: return .appSoftIndigo.opacity(0.08)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .appForeground
        case .destructive: return .appDestructive
        case .subtle: return .appSoftIndigo
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return .appBorder
        case .destructive: return .appDestructive.opacity(0.5)
        case .subtle: return .appSoftIndigo.opacity(0.3)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leadingIcon = leadingIcon ?? icon {
                    Image(systemName: leadingIcon)
                        .font(.system(size: ScreenScale.font(16), weight: .bold))
                }
                Text(title)
                    .font(.system(size: ScreenScale.font(15), weight: .bold))
                    .tracking(-0.3)
                if let trailingIcon = trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: ScreenScale.font(16), weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .scaledPadding(.vertical, 20.0)
            .scaledPadding(.horizontal, 20.0)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: style == .primary ? 0 : 1)
            )
            .opacity(isDisabled ? 0.4 : 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(ScaleButtonStyle())
        .shadow(
            color: shadowColor,
            radius: hasShadow ? 12 : 0,
            x: 0,
            y: 0
        )
    }

    private var hasShadow: Bool {
        switch style {
        case .primary, .subtle: return true
        default: return false
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary: return Color.appPrimary.opacity(0.2)
        case .subtle: return Color.appSoftIndigo.opacity(0.15)
        default: return .clear
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.quickSpring, value: configuration.isPressed)
    }
}
