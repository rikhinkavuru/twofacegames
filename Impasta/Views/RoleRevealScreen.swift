import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RoleRevealScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) private var theme

    @State private var isFlipped = false
    @State private var showControls = false
    @State private var animateBackdrop = false

    private var isHost: Bool { viewModel.isHost }

    var body: some View {
        ZStack {
            RoleRevealBackdrop(
                animateBackdrop: animateBackdrop,
                highlightColor: activeAccent.opacity(0.34),
                secondaryColor: secondaryAccent.opacity(0.28)
            )

            if let game = viewModel.game, let currentPlayer = viewModel.currentPlayer {
                VStack(spacing: ScreenScale.height(24)) {
                    header(for: currentPlayer)
                        .scaledPadding(.top, 28.0)

                    Spacer(minLength: ScreenScale.height(10))

                    flipCard(game: game, currentPlayer: currentPlayer)
                        .scaledFrame(height: 420)
                        .onTapGesture {
                            guard !isFlipped else { return }
                            #if canImport(UIKit)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            #endif
                            #endif
                            withAnimation(.spring(response: 0.82, dampingFraction: 0.82)) {
                                isFlipped = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                withAnimation(.smoothSpring) {
                                    showControls = true
                                }
                            }
                        }

                    Spacer(minLength: ScreenScale.height(10))

                    controlsView
                        .opacity(showControls ? 1 : 0)
                        .offset(y: showControls ? 0 : 20)
                        .animation(.smoothSpring, value: showControls)

                    Spacer(minLength: ScreenScale.height(12))
                }
                .scaledPadding(.horizontal, 22.0)

                homeButtonOverlay
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animateBackdrop = true
            }
        }
    }

    private var activeAccent: Color {
        if let currentPlayer = viewModel.currentPlayer, isFlipped {
            return currentPlayer.isImposter ? theme.imposter : theme.civilian
        }
        return theme.accent
    }

    private var secondaryAccent: Color {
        if let currentPlayer = viewModel.currentPlayer, isFlipped {
            return currentPlayer.isImposter ? theme.warning : theme.success
        }
        return theme.accentSecondary
    }

    private func header(for currentPlayer: Player) -> some View {
        VStack(spacing: ScreenScale.height(18)) {
            HStack(spacing: 10) {
                statusChip(label: "SECURE CHANNEL", color: theme.accent)
                statusChip(label: currentPlayer.isImposter ? "IMPOSTER SIGNAL" : "CIVILIAN SIGNAL", color: currentPlayer.isImposter ? theme.imposter : theme.civilian)
            }

            VStack(spacing: 12) {
                Text("ROLE REVEAL")
                    .font(.appCaption)
                    .foregroundColor(theme.textSecondary.opacity(0.85))
                    .tracking(3)

                Text(isFlipped
                     ? (currentPlayer.isImposter ? "YOU ARE THE IMPOSTER" : "YOU ARE A CIVILIAN")
                     : "REVEAL YOUR IDENTITY")
                    .font(.system(size: ScreenScale.font(28), weight: .bold))
                    .tracking(-1)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(isFlipped
                     ? (currentPlayer.isImposter
                        ? "Your clue feed is live. Blend into the conversation."
                        : "Protect the word. Watch the tells. Vote with intent.")
                     : "Tap the encrypted card when you are ready.")
                    .font(.system(size: ScreenScale.font(13), weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func statusChip(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: ScreenScale.font(10), weight: .bold))
            .tracking(1.8)
            .foregroundColor(color)
            .scaledPadding(.horizontal, 12.0)
            .scaledPadding(.vertical, 8.0)
            .background(
                Capsule()
                    .fill(theme.surface.opacity(0.72))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.42), lineWidth: 1)
                    )
            )
            .neonGlow(color: color)
    }

    private var controlsView: some View {
        Group {
            if showControls {
                VStack(spacing: ScreenScale.height(18)) {
                    if isHost {
                        VStack(spacing: ScreenScale.height(14)) {
                            Text("HOST CONTROL")
                                .font(.appCaption)
                                .foregroundColor(theme.textSecondary.opacity(0.78))
                                .tracking(3)

                            PillButton(
                                title: "EVERYONE READY",
                                trailingIcon: "chevron.right",
                                style: .primary
                            ) {
                                Task { await viewModel.proceedToClues() }
                            }
                        }
                    } else {
                        VStack(spacing: ScreenScale.height(18)) {
                            WaitingIndicator(message: "Waiting for host")

                            Button {
                                Task { await viewModel.refreshState() }
                            } label: {
                                Label("STUCK? REFRESH", systemImage: "arrow.clockwise")
                                    .font(.system(size: ScreenScale.font(12), weight: .bold))
                                    .foregroundColor(theme.accentSecondary)
                                    .tracking(1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .scaledPadding(.all, 22.0)
                .background(panelBackground(accent: activeAccent))
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(panelBorder(accent: activeAccent, lineWidth: 1))
                .premiumShadow()
            }
        }
    }

    private func flipCard(game: Game, currentPlayer: Player) -> some View {
        ZStack {
            frontCard
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            backCard(game: game, currentPlayer: currentPlayer)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .animation(.spring(response: 0.82, dampingFraction: 0.82), value: isFlipped)
    }

    private var frontCard: some View {
        VStack(spacing: ScreenScale.height(26)) {
            ZStack {
                Circle()
                    .stroke(theme.border.opacity(0.7), lineWidth: 1)
                    .scaledFrame(width: 150, height: 150)
                    .overlay(
                        Circle()
                            .trim(from: 0.08, to: 0.72)
                            .stroke(theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(animateBackdrop ? 360 : 0))
                            .animation(.linear(duration: 12).repeatForever(autoreverses: false), value: animateBackdrop)
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.accentSecondary.opacity(0.45), theme.surface.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: 90
                        )
                    )
                    .scaledFrame(width: 110, height: 110)

                Image(systemName: "wave.3.right.circle.fill")
                    .font(.system(size: ScreenScale.font(54), weight: .bold))
                    .foregroundStyle(theme.textPrimary, theme.accent)
                    .neonGlow(color: theme.accent)
            }

            VStack(spacing: 10) {
                Text("ENCRYPTED ROLE CARD")
                    .font(.appCaption)
                    .foregroundColor(theme.textSecondary.opacity(0.8))
                    .tracking(3)

                Text("TAP TO DECRYPT")
                    .font(.system(size: ScreenScale.font(20), weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .tracking(-0.8)

                Text("Pass the device privately, then reveal.")
                    .font(.system(size: ScreenScale.font(13), weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaledPadding(.all, 28.0)
        .background(panelBackground(accent: theme.accentSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay(panelBorder(accent: theme.accent, lineWidth: 1.2))
        .premiumShadow()
    }

    private func backCard(game: Game, currentPlayer: Player) -> some View {
        let isImposter = currentPlayer.isImposter
        let accent = isImposter ? theme.imposter : theme.civilian
        let supporting = isImposter ? theme.warning : theme.success

        return VStack(spacing: ScreenScale.height(24)) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .scaledFrame(width: 128, height: 128)
                    .overlay(
                        Circle()
                            .stroke(accent.opacity(0.5), lineWidth: 1.5)
                    )
                    .neonGlow(color: accent)

                Image(systemName: isImposter ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: ScreenScale.font(48), weight: .bold))
                    .foregroundColor(accent)
            }

            VStack(spacing: 12) {
                Text(isImposter ? "YOUR CLUE" : "THE SECRET WORD")
                    .font(.appCaption)
                    .foregroundColor(theme.textSecondary.opacity(0.8))
                    .tracking(3)

                Text((isImposter ? game.imposterClue : game.word) ?? "")
                    .font(.system(size: ScreenScale.font(42), weight: .black))
                    .foregroundColor(theme.textPrimary)
                    .textCase(.uppercase)
                    .tracking(-1.8)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.45)
                    .lineLimit(2)
                    .neonGlow(color: accent)

                Text(isImposter ? "Blend in with clues that feel informed, not obvious." : "Guard the signal and track suspicious clues.")
                    .font(.system(size: ScreenScale.font(13), weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                roleMetric(title: "ROLE", value: isImposter ? "IMPOSTER" : "CIVILIAN", accent: accent)
                roleMetric(title: "MODE", value: isImposter ? "DECEIVE" : "DETECT", accent: supporting)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaledPadding(.all, 28.0)
        .background(panelBackground(accent: accent))
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay(panelBorder(accent: accent, lineWidth: 1.4))
        .premiumShadow()
    }

    private func roleMetric(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: ScreenScale.font(10), weight: .bold))
                .tracking(2)
                .foregroundColor(theme.textSecondary.opacity(0.85))
            Text(value)
                .font(.system(size: ScreenScale.font(12), weight: .bold))
                .foregroundColor(accent)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.vertical, 12.0)
        .background(theme.surfaceElevated.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.35), lineWidth: 1)
        )
    }

    private func panelBackground(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.surface.opacity(0.94), theme.surfaceElevated.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.2), .clear],
                            center: .topTrailing,
                            startRadius: 10,
                            endRadius: 220
                        )
                    )
            )
    }

    private func panelBorder(accent: Color, lineWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [accent.opacity(0.7), theme.border.opacity(0.75), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: lineWidth
            )
    }

    private var homeButtonOverlay: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    #if canImport(UIKit)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    #endif
                    viewModel.exitGame()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: ScreenScale.font(14), weight: .bold))
                        .foregroundColor(theme.textPrimary)
                        .scaledPadding(.all, 12.0)
                        .background(
                            Circle()
                                .fill(theme.surface.opacity(0.82))
                                .overlay(Circle().stroke(theme.border.opacity(0.6), lineWidth: 1))
                        )
                        .neonGlow(color: theme.accentSecondary)
                }
            }
            .scaledPadding(.horizontal, 20.0)
            .scaledPadding(.top, 20.0)

            Spacer()
        }
    }
}

private struct RoleRevealBackdrop: View {
    @Environment(\.theme) private var theme

    let animateBackdrop: Bool
    let highlightColor: Color
    let secondaryColor: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.background, theme.surfaceElevated.opacity(0.92), theme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 0)
                .stroke(theme.border.opacity(0.14), style: StrokeStyle(lineWidth: 1, dash: [6, 8]))
                .rotationEffect(.degrees(animateBackdrop ? 4 : -4))
                .scaleEffect(1.15)
                .ignoresSafeArea()

            Circle()
                .fill(highlightColor)
                .scaledFrame(width: 280, height: 280)
                .blur(radius: 48)
                .offset(x: animateBackdrop ? 120 : -130, y: -260)

            Circle()
                .fill(secondaryColor)
                .scaledFrame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: animateBackdrop ? -110 : 140, y: 280)

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [theme.border.opacity(0.06), .clear, theme.border.opacity(0.06)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaledFrame(height: 140)
                    .blur(radius: 18)
                    .offset(y: animateBackdrop ? 12 : -12)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}
