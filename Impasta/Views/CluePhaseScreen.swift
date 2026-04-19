import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CluePhaseScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) private var theme

    @State private var clue = ""
    @State private var animateBackdrop = false

    private var players: [Player] { viewModel.players }

    private var clueState: (
        game: Game,
        currentPlayer: Player,
        clueRoundState: ClueRoundState,
        isMyTurn: Bool,
        hasSubmitted: Bool
    )? {
        guard let game = viewModel.game, let currentPlayer = viewModel.currentPlayer else { return nil }

        let state = getClueRoundState(
            players: players,
            clueRounds: game.clueRounds,
            currentTurnIndex: game.currentTurnIndex
        )

        let isMyTurn = state.activePlayer?.id == currentPlayer.id
        let hasSubmitted = isMyTurn && hasClueForRound(state.activePlayer?.clue, round: state.currentRound)

        return (game, currentPlayer, state, isMyTurn, hasSubmitted)
    }

    var body: some View {
        ZStack {
            CluePhaseBackdrop(animateBackdrop: animateBackdrop)

            if let state = clueState {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ScreenScale.height(20)) {
                        header(state: state)

                        turnList(state: state)

                        if state.isMyTurn && !state.hasSubmitted {
                            clueComposer
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            waitingPanel(state: state)
                        }

                        Spacer(minLength: ScreenScale.height(30))
                    }
                    .scaledPadding(.horizontal, 20.0)
                    .scaledPadding(.top, 24.0)
                    .scaledPadding(.bottom, 24.0)
                }
                .onChange(of: state.game.currentTurnIndex) { _, _ in
                    clue = ""
                }

                homeButtonOverlay
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animateBackdrop = true
            }
        }
    }

    private func header(state: (game: Game, currentPlayer: Player, clueRoundState: ClueRoundState, isMyTurn: Bool, hasSubmitted: Bool)) -> some View {
        VStack(spacing: ScreenScale.height(16)) {
            HStack(spacing: 10) {
                infoChip(title: "ROUND \(state.clueRoundState.currentRound)/\(state.game.clueRounds)", accent: theme.accent)
                infoChip(title: state.isMyTurn && !state.hasSubmitted ? "LIVE TURN" : "MONITORING", accent: state.isMyTurn && !state.hasSubmitted ? theme.success : theme.accentSecondary)
            }

            VStack(spacing: 10) {
                Text("CLUE PHASE")
                    .font(.appCaption)
                    .foregroundColor(theme.textSecondary.opacity(0.82))
                    .tracking(3)

                Text(state.isMyTurn && !state.hasSubmitted
                     ? "IT'S YOUR TURN"
                     : state.clueRoundState.activePlayer != nil
                     ? "WAITING FOR \(state.clueRoundState.activePlayer!.name.uppercased())"
                     : "WAITING...")
                    .font(.system(size: ScreenScale.font(28), weight: .bold))
                    .tracking(-1)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("One word only. Keep it subtle and believable.")
                    .font(.system(size: ScreenScale.font(13), weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.all, 22.0)
        .background(shellBackground(accent: state.isMyTurn ? theme.success : theme.accent))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(shellBorder(accent: state.isMyTurn ? theme.success : theme.accent))
        .premiumShadow()
    }

    private func turnList(state: (game: Game, currentPlayer: Player, clueRoundState: ClueRoundState, isMyTurn: Bool, hasSubmitted: Bool)) -> some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(14)) {
            Text("TURN ORDER")
                .font(.appCaption)
                .foregroundColor(theme.textSecondary.opacity(0.82))
                .tracking(3)

            VStack(spacing: ScreenScale.height(12)) {
                ForEach(Array(state.clueRoundState.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    let isActive = index == state.clueRoundState.turnInRound
                    let isDone = index < state.clueRoundState.turnInRound ||
                        (isActive && hasClueForRound(player.clue, round: state.clueRoundState.currentRound))
                    let latestClue = parseClues(player.clue).last
                    playerRow(
                        index: index,
                        player: player,
                        currentPlayer: state.currentPlayer,
                        latestClue: latestClue,
                        isActive: isActive,
                        isDone: isDone
                    )
                }
            }
        }
        .scaledPadding(.all, 20.0)
        .background(shellBackground(accent: theme.accentSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(shellBorder(accent: theme.accentSecondary))
        .premiumShadow()
    }

    private func playerRow(index: Int, player: Player, currentPlayer: Player, latestClue: String?, isActive: Bool, isDone: Bool) -> some View {
        let accent = isActive ? theme.accent : (isDone ? theme.success : theme.border)

        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isActive ? accent.opacity(0.22) : theme.surfaceElevated.opacity(isDone ? 0.92 : 0.72))
                    .scaledFrame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(accent.opacity(isActive ? 0.7 : 0.35), lineWidth: 1)
                    )

                Group {
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: ScreenScale.font(12), weight: .bold))
                            .foregroundColor(theme.success)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: ScreenScale.font(11), weight: .bold))
                            .foregroundColor(isActive ? theme.accent : theme.textSecondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(player.name)
                        .font(.system(size: ScreenScale.font(15), weight: .bold))
                        .foregroundColor(theme.textPrimary)

                    if player.id == currentPlayer.id {
                        Text("YOU")
                            .font(.system(size: ScreenScale.font(10), weight: .bold))
                            .foregroundColor(theme.accentSecondary)
                            .tracking(1)
                    }
                }

                Text(isDone ? "TRANSMISSION LOGGED" : (isActive ? "SIGNAL LIVE" : "STANDBY"))
                    .font(.system(size: ScreenScale.font(10), weight: .bold))
                    .foregroundColor(isActive ? theme.accent : theme.textSecondary.opacity(0.82))
                    .tracking(1.5)
            }

            Spacer()

            if let latestClue = latestClue {
                Text("“\(latestClue.uppercased())”")
                    .font(.system(size: ScreenScale.font(13), weight: .bold))
                    .foregroundColor(isActive ? theme.accent : theme.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
        }
        .scaledPadding(.horizontal, 18.0)
        .scaledPadding(.vertical, 16.0)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surface.opacity(isActive ? 0.92 : 0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(isActive ? 0.2 : 0.08), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(isActive ? 0.8 : 0.34), lineWidth: isActive ? 1.5 : 1)
        )
        .if(isActive) { view in
            view.neonGlow(color: theme.accent)
        }
        .animation(.smoothSpring, value: isActive)
    }

    private var clueComposer: some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(20)) {
            Text("YOUR CLUE")
                .font(.appCaption)
                .foregroundColor(theme.textSecondary.opacity(0.82))
                .tracking(3)

            VStack(alignment: .leading, spacing: 12) {
                TextField("TYPE WORD...", text: $clue)
                    .font(.system(size: ScreenScale.font(30), weight: .bold))
                    .tracking(-1)
                    .foregroundColor(theme.textPrimary)
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
                    .autocorrectionDisabled()
                    .onChange(of: clue) { _, newValue in
                        clue = newValue.replacingOccurrences(of: " ", with: "")
                        if clue.count > 30 { clue = String(clue.prefix(30)) }
                    }
                    .onSubmit { submitClue() }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaledFrame(height: 2)
                    .clipShape(Capsule())
                    .neonGlow(color: theme.accent)

                HStack {
                    Text("NO SPACES • MAX 30 CHARACTERS")
                        .font(.system(size: ScreenScale.font(10), weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.85))
                        .tracking(1.2)
                    Spacer()
                    Text("\(clue.count)/30")
                        .font(.system(size: ScreenScale.font(10), weight: .bold))
                        .foregroundColor(theme.accentSecondary)
                }
            }

            PillButton(
                title: "SEND CLUE",
                trailingIcon: "arrow.right",
                style: .primary,
                isDisabled: clue.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                submitClue()
            }
        }
        .scaledPadding(.all, 22.0)
        .background(shellBackground(accent: theme.success))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(shellBorder(accent: theme.success))
        .premiumShadow()
    }

    private func waitingPanel(state: (game: Game, currentPlayer: Player, clueRoundState: ClueRoundState, isMyTurn: Bool, hasSubmitted: Bool)) -> some View {
        VStack(spacing: ScreenScale.height(18)) {
            WaitingIndicator(message: state.hasSubmitted ? "Clue sent" : "Monitoring live turn")

            Button {
                Task { await viewModel.refreshState() }
            } label: {
                Label("STUCK? REFRESH", systemImage: "arrow.clockwise")
                    .font(.system(size: ScreenScale.font(12), weight: .bold))
                    .foregroundColor(theme.accentSecondary)
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.all, 22.0)
        .background(shellBackground(accent: theme.accentSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(shellBorder(accent: theme.accentSecondary))
        .premiumShadow()
    }

    private func infoChip(title: String, accent: Color) -> some View {
        Text(title)
            .font(.system(size: ScreenScale.font(10), weight: .bold))
            .tracking(1.8)
            .foregroundColor(accent)
            .scaledPadding(.horizontal, 12.0)
            .scaledPadding(.vertical, 8.0)
            .background(
                Capsule()
                    .fill(theme.surface.opacity(0.76))
                    .overlay(Capsule().stroke(accent.opacity(0.4), lineWidth: 1))
            )
            .neonGlow(color: accent)
    }

    private func shellBackground(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.surface.opacity(0.94), theme.surfaceElevated.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.18), .clear],
                            center: .topTrailing,
                            startRadius: 10,
                            endRadius: 220
                        )
                    )
            )
    }

    private func shellBorder(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [accent.opacity(0.62), theme.border.opacity(0.75), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
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
                                .overlay(Circle().stroke(theme.border.opacity(0.65), lineWidth: 1))
                        )
                        .neonGlow(color: theme.accent)
                }
            }
            .scaledPadding(.horizontal, 20.0)
            .scaledPadding(.top, 20.0)

            Spacer()
        }
    }

    private func submitClue() {
        let trimmed = clue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { await viewModel.submitClue(trimmed) }
    }
}

private struct CluePhaseBackdrop: View {
    @Environment(\.theme) private var theme

    let animateBackdrop: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.background, theme.surfaceElevated.opacity(0.94), theme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 44) {
                ForEach(0..<9, id: \.self) { _ in
                    Rectangle()
                        .fill(theme.border.opacity(0.08))
                        .scaledFrame(height: 1)
                }
            }
            .rotationEffect(.degrees(-10))
            .scaleEffect(1.3)
            .ignoresSafeArea()

            Circle()
                .fill(theme.accent.opacity(0.22))
                .scaledFrame(width: 280, height: 280)
                .blur(radius: 52)
                .offset(x: animateBackdrop ? 110 : -120, y: -280)

            Circle()
                .fill(theme.accentSecondary.opacity(0.18))
                .scaledFrame(width: 260, height: 260)
                .blur(radius: 56)
                .offset(x: animateBackdrop ? -130 : 120, y: 260)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, theme.success.opacity(0.18), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaledFrame(height: 170)
                .blur(radius: 18)
                .rotationEffect(.degrees(18))
                .offset(x: animateBackdrop ? 120 : -120, y: animateBackdrop ? 70 : -30)
                .ignoresSafeArea()
        }
    }
}
