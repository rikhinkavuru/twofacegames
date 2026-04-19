import SwiftUI

// MARK: - Waiting Indicator (bouncing dots)
struct WaitingIndicator: View {
    var message: String? = nil

    @State private var animating = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
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
                }
            }

            if let message = message {
                Text(message)
                    .font(.appCaption)
                    .foregroundColor(.appMutedForeground.opacity(0.6))
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
        case 0: return .appSoftIndigo
        case 1: return .appSoftSlate
        case 2: return .appSoftSage
        default: return .appPrimary
        }
    }
}
