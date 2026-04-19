import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AppSegmentedControl<T: Hashable>: View {
    @Environment(\.theme) private var theme

    let options: [T]
    @Binding var selected: T
    let label: (T) -> AnyView
    private let cornerRadius: CGFloat = 16

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isActive = option == selected

                Button(action: {
                    #if canImport(UIKit)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    #endif
                    withAnimation(.quickSpring) {
                        selected = option
                    }
                }) {
                    label(option)
                        .font(.system(size: ScreenScale.font(13), weight: .semibold))
                        .foregroundColor(isActive ? theme.textOnAccent : theme.textSecondary)
                        .scaledPadding(.vertical, 12.0)
                        .frame(maxWidth: .infinity)
                        .background(isActive ? theme.accent : theme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .if(isActive) { view in
                            view.neonGlow(color: theme.accent)
                        }
                }
            }
        }
        .scaledPadding(.all, 4.0)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(theme.border.opacity(0.7), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SettingsRow<Content: View>: View {
    @Environment(\.theme) private var theme

    let label: String
    let content: () -> Content

    init(label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label.uppercased())
                .font(.system(size: ScreenScale.font(10), weight: .bold))
                .foregroundColor(theme.textSecondary.opacity(0.72))
                .tracking(2)
                .scaledPadding(.leading, 20.0)

            content()
        }
    }
}
