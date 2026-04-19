import SwiftUI

struct PillButton: View {
    @Environment(\.theme) private var theme

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
        case subtle
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return theme.accent
        case .secondary:
            return theme.surface
        case .destructive:
            return theme.destructive.opacity(0.14)
        case .subtle:
            return theme.accentSecondary.opacity(0.14)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return theme.textOnAccent
        case .secondary:
            return theme.textPrimary
        case .destructive:
            return theme.destructive
        case .subtle:
            return theme.accentSecondary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return theme.border
        case .destructive:
            return theme.destructive.opacity(0.45)
        case .subtle:
            return theme.accentSecondary.opacity(0.28)
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
            .opacity(isDisabled ? 0.45 : 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(ScaleButtonStyle())
        .shadow(color: shadowColor, radius: hasShadow ? 14 : 0, x: 0, y: 0)
    }

    private var hasShadow: Bool {
        switch style {
        case .primary, .subtle:
            return true
        default:
            return false
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return theme.accent.opacity(0.35)
        case .subtle:
            return theme.accentSecondary.opacity(0.28)
        default:
            return .clear
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.quickSpring, value: configuration.isPressed)
    }
}
