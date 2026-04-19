import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Custom Segmented Control
struct AppSegmentedControl<T: Hashable>: View {
    let options: [T]
    @Binding var selected: T
    let label: (T) -> AnyView

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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = option
                    }
                }) {
                    label(option)
                        .font(.system(size: ScreenScale.font(13), weight: .semibold))
                        .foregroundColor(isActive ? .white : .black.opacity(0.6))
                        .scaledPadding(.vertical, 12.0)
                        .frame(maxWidth: .infinity)
                        .background(
                            isActive ? Color.black : Color.black.opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaledPadding(.all, 4.0)
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
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
                .foregroundColor(.black.opacity(0.3))
                .tracking(2)
                .scaledPadding(.leading, 20.0)

            content()
        }
    }
}
