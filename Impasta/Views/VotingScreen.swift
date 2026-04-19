import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct VotingScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) private var theme

    @State private var selectedIds: Set<String> = []
    @State private var skipVote = false
    @State private var animateBackdrop = false

    private var players: [Player] { viewModel.players }

    private var votingState: (
        currentPlayer: Player,
        hasVoted: Bool,
        currentVotes: [String],
        votedCount: Int
    )? {
        guard let _ = viewModel.game, let currentPlayer = viewModel.currentPlayer else { return nil }

        let hasVoted = currentPlayer.hasVoted
        let currentVotes = parseVoteIds(currentPlayer.voteFor)
        let votedCount = players.filter { $0.hasVoted }.count

        return (currentPlayer, hasVoted, currentVotes, votedCount)
    }

    var body: some View {
        ZStack {
            VotingBackdrop(animateBackdrop: animateBackdrop)

            if let state = votingState {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ScreenScale.height(20)) {
                        header(state: state)

                        playerGrid(state: state)

                        if !state.hasVoted {
                            actionPanel
                        } else {
                            waitingPanel(state: state)
                        }

                        Spacer(minLength: ScreenScale.height(28))
                    }
                    .scaledPadding(.horizontal, 20.0)
                    .scaledPadding(.top, 24.0)
                    .scaledPadding(.bottom, 24.0)
                }

                homeButtonOverlay
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9.5).repeatForever(autoreverses: true)) {
                animateBackdrop = true
            }
        }
    }

    private func header(state: (currentPlayer: Player, hasVoted: Bool, currentVotes: [String], votedCount: Int)) -> some View {
        VStack(spacing: ScreenScale.height(16)) {
            HStack(spacing: 10) {
                voteChip(title: "VOTED \(state.votedCount)/\(players.count)", accent: theme.accent)
                voteChip(title: state.hasVoted ? "BALLOT SENT" : "SELECT TARGETS", accent: state.hasVoted ? theme.success : theme.imposter)
            }

            VStack(spacing: 10) {
                Text("VOTING PHASE")
                    .font(.appCaption)
                    .foregroundColor(theme.textSecondary.opacity(0.82))
                    .tracking(3)

                Text(state.hasVoted ? "VOTES CAST" : "WHO IS THE IMPOSTER?")
                    .font(.system(size: ScreenScale.font(28), weight: .bold))
                    .tracking(-1)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(state.hasVoted ? "Waiting for the rest of the room to lock in." : "Select the suspects, or skip if nobody looks guilty.")
                    .font(.system(size: ScreenScale.font(13), weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.all, 22.0)
        .background(panelBackground(accent: theme.imposter))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(panelBorder(accent: theme.imposter))
        .premiumShadow()
    }

    private func playerGrid(state: (currentPlayer: Player, hasVoted: Bool, currentVotes: [String], votedCount: Int)) -> some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(14)) {
            Text("SUSPECT MATRIX")
                .font(.appCaption)
                .foregroundColor(theme.textSecondary.opacity(0.82))
                .tracking(3)

            VStack(spacing: ScreenScale.height(12)) {
                ForEach(players) { player in
                    let isSelf = player.id == state.currentPlayer.id
                    let isSelected = selectedIds.contains(player.id) && !skipVote
                    let isVotedFor = state.hasVoted && state.currentVotes.contains(player.id)
                    voteRow(player: player, isSelf: isSelf, isSelected: isSelected, isVotedFor: isVotedFor, hasVoted: state.hasVoted)
                }
            }
        }
        .scaledPadding(.all, 20.0)
        .background(panelBackground(accent: theme.accentSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(panelBorder(accent: theme.accentSecondary))
        .premiumShadow()
    }

    private func voteRow(player: Player, isSelf: Bool, isSelected: Bool, isVotedFor: Bool, hasVoted: Bool) -> some View {
        let accent = isSelected || isVotedFor ? theme.imposter : theme.border

        return Button {
            guard !hasVoted, !isSelf else { return }
            skipVote = false
            if selectedIds.contains(player.id) {
                selectedIds.remove(player.id)
            } else {
                selectedIds.insert(player.id)
            }
            #if canImport(UIKit)
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            #endif
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill((isSelected || isVotedFor ? theme.imposter : theme.accent).opacity(0.18))
                        .scaledFrame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke((isSelected || isVotedFor ? theme.imposter : theme.accent).opacity(0.48), lineWidth: 1)
                        )

                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: ScreenScale.font(16), weight: .bold))
                        .foregroundColor(isSelected || isVotedFor ? theme.imposter : theme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(player.name)
                            .font(.system(size: ScreenScale.font(15), weight: .bold))
                            .foregroundColor(theme.textPrimary)

                        if isSelf {
                            Text("YOU")
                                .font(.system(size: ScreenScale.font(10), weight: .bold))
                                .foregroundColor(theme.accentSecondary)
                                .tracking(1)
                        }
                    }

                    let clues = parseClues(player.clue)
                    if !clues.isEmpty {
                        Text(clues.joined(separator: " • ").uppercased())
                            .font(.system(size: ScreenScale.font(10), weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.8))
                            .tracking(1.1)
                            .lineLimit(2)
                    } else {
                        Text("NO CLUE LOGGED")
                            .font(.system(size: ScreenScale.font(10), weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.66))
                            .tracking(1.1)
                    }
                }

                Spacer()

                if isSelected || isVotedFor {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: ScreenScale.font(26), weight: .bold))
                        .foregroundColor(theme.imposter)
                        .neonGlow(color: theme.imposter)
                } else if !isSelf && !hasVoted {
                    Circle()
                        .stroke(theme.border, lineWidth: 2)
                        .scaledFrame(width: 24, height: 24)
                }
            }
            .scaledPadding(.all, 18.0)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.surface.opacity(isSelf ? 0.66 : 0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [(isSelected || isVotedFor ? theme.imposter : theme.accentSecondary).opacity(0.16), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(accent.opacity(isSelected || isVotedFor ? 0.82 : 0.34), lineWidth: isSelected || isVotedFor ? 1.5 : 1)
            )
            .opacity(isSelf ? 0.7 : 1)
        }
        .buttonStyle(.plain)
        .disabled(hasVoted || isSelf)
    }

    private var actionPanel: some View {
        VStack(spacing: ScreenScale.height(18)) {
            Button {
                withAnimation(.quickSpring) {
                    skipVote.toggle()
                    if skipVote { selectedIds.removeAll() }
                }
                #if canImport(UIKit)
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                #endif
                #endif
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: skipVote ? "xmark.circle.fill" : "circle")
                    Text("SKIP VOTE (NOBODY IS SUSPICIOUS)")
                        .font(.appCaption)
                        .tracking(1)
                }
                .foregroundColor(skipVote ? theme.warning : theme.textSecondary)
            }

            PillButton(
                title: selectedIds.count > 1 ? "SUBMIT \(selectedIds.count) VOTES" : "SUBMIT VOTE",
                trailingIcon: "hand.raised.fill",
                style: .primary,
                isDisabled: selectedIds.isEmpty && !skipVote
            ) {
                Task {
                    if skipVote {
                        await viewModel.submitVote(votedPlayerIds: [])
                    } else {
                        await viewModel.submitVote(votedPlayerIds: Array(selectedIds))
                    }
                }
            }
        }
        .scaledPadding(.all, 22.0)
        .background(panelBackground(accent: skipVote ? theme.warning : theme.imposter))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(panelBorder(accent: skipVote ? theme.warning : theme.imposter))
        .premiumShadow()
    }

    private func waitingPanel(state: (currentPlayer: Player, hasVoted: Bool, currentVotes: [String], votedCount: Int)) -> some View {
        VStack(spacing: ScreenScale.height(18)) {
            WaitingIndicator(message: "WAITING FOR OTHERS (\(state.votedCount)/\(players.count))")

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
        .background(panelBackground(accent: theme.success))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(panelBorder(accent: theme.success))
        .premiumShadow()
    }

    private func voteChip(title: String, accent: Color) -> some View {
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

    private func panelBackground(accent: Color) -> some View {
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
                            startRadius: 12,
                            endRadius: 240
                        )
                    )
            )
    }

    private func panelBorder(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [accent.opacity(0.68), theme.border.opacity(0.76), .clear],
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
                        .neonGlow(color: theme.imposter)
                }
            }
            .scaledPadding(.horizontal, 20.0)
            .scaledPadding(.top, 20.0)

            Spacer()
        }
    }
}

private struct VotingBackdrop: View {
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

            Circle()
                .fill(theme.imposter.opacity(0.2))
                .scaledFrame(width: 300, height: 300)
                .blur(radius: 58)
                .offset(x: animateBackdrop ? 120 : -130, y: -270)

            Circle()
                .fill(theme.accentSecondary.opacity(0.18))
                .scaledFrame(width: 260, height: 260)
                .blur(radius: 56)
                .offset(x: animateBackdrop ? -120 : 130, y: 260)

            RoundedRectangle(cornerRadius: 0)
                .stroke(theme.border.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [7, 9]))
                .rotationEffect(.degrees(animateBackdrop ? 8 : -8))
                .scaleEffect(1.2)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                ForEach(0..<10, id: \.self) { _ in
                    Rectangle()
                        .fill(theme.border.opacity(0.05))
                        .scaledFrame(height: 1)
                }
            }
            .rotationEffect(.degrees(12))
            .scaleEffect(1.45)
            .ignoresSafeArea()
        }
    }
}
