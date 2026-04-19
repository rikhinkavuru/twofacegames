import SwiftUI

struct WaitingIndicator: View {
    @Environment(\.theme) private var theme

    var message: String? = nil

    @State private var animating = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .scaledFrame(width: 8, height: 8)
                        .offset(y: animating ? -6 : 0)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                        .neonGlow(color: dotColor(for: index))
                }
            }

            if let message = message {
                Text(message)
                    .font(.appCaption)
                    .foregroundColor(theme.textSecondary.opacity(0.8))
                    .tracking(3)
                    .textCase(.uppercase)
            }
        }
        .scaledPadding(.vertical, 20.0)
        .onAppear {
            animating = true
        }
    }

    private func dotColor(for index: Int) -> Color {
        switch index {
        case 0:
            return theme.accent
        case 1:
            return theme.accentSecondary
        case 2:
            return theme.success
        default:
            return theme.textPrimary
        }
    }
}
