import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct VotingScreen: View {
    @ObservedObject var viewModel: GameViewModel

    @State private var selectedIds: Set<String> = []
    @State private var skipVote = false

    private var players: [Player] { viewModel.players }
    
    // MARK: - Computed Properties for Voting State
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
            Color.appBackground.ignoresSafeArea()

            if let state = votingState {
                ScrollView {
                    VStack(spacing: 48) {
                        // Header (Centered)
                        VStack(spacing: 16) {
                            Text("VOTING PHASE")
                                .font(.appCaption)
                                .foregroundColor(.appMutedForeground.opacity(0.6))
                                .tracking(3)

                            Text(state.hasVoted ? "VOTES CAST" : "WHO IS THE IMPOSTER?")
                                .font(.system(size: ScreenScale.font(22), weight: .medium))
                                .tracking(-0.5)
                                .foregroundColor(.appForeground)
                                .multilineTextAlignment(.center)

                            Text(state.hasVoted ? "Waiting for others..." : "Select the suspects.")
                                .font(.system(size: ScreenScale.font(12), weight: .medium))
                                .foregroundColor(.appMutedForeground.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .scaledPadding(.top, 20.0)

                        // Voting Cards
                        VStack(spacing: 12) {
                            ForEach(players) { player in
                                let isSelf = player.id == state.currentPlayer.id
                                let isSelected = selectedIds.contains(player.id) && !skipVote
                                let isVotedFor = state.hasVoted && state.currentVotes.contains(player.id)

                                Button {
                                    guard !state.hasVoted, !isSelf else { return }
                                    skipVote = false
                                    if selectedIds.contains(player.id) {
                                        selectedIds.remove(player.id)
                                    } else {
                                        selectedIds.insert(player.id)
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        // Avatar
                                        Circle()
                                            .fill(Color.appPrimary.opacity(0.1))
                                            .scaledFrame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(player.name.prefix(1)).uppercased())
                                                    .font(.system(size: ScreenScale.font(14), weight: .medium))
                                                    .foregroundColor(.appPrimary)
                                            )

                                        // Info
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(player.name)
                                                    .font(.system(size: ScreenScale.font(15), weight: .medium))
                                                    .foregroundColor(.appForeground)

                                                if isSelf {
                                                    Text("YOU")
                                                        .font(.system(size: ScreenScale.font(10), weight: .medium))
                                                        .foregroundColor(.appMutedForeground.opacity(0.6))
                                                }
                                            }

                                            let clues = parseClues(player.clue)
                                            if !clues.isEmpty {
                                                Text(clues.joined(separator: " \u{2022} ").uppercased())
                                                    .font(.system(size: ScreenScale.font(10), weight: .medium))
                                                    .foregroundColor(.appMutedForeground.opacity(0.5))
                                                    .tracking(1)
                                            }
                                        }

                                        Spacer()

                                        // Selection Indicator
                                        if isSelected || isVotedFor {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: ScreenScale.font(24)))
                                                .foregroundColor(.appPrimary)
                                        } else if !isSelf && !state.hasVoted {
                                            Circle()
                                                .stroke(Color.appBorder, lineWidth: 2)
                                                .scaledFrame(width: 24, height: 24)
                                        }
                                    }
                                    .scaledPadding(.all, 20.0)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .premiumShadow()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(
                                                (isSelected || isVotedFor) ? Color.appPrimary.opacity(0.5) : Color.appBorder.opacity(0.3),
                                                lineWidth: (isSelected || isVotedFor) ? 2 : 1
                                            )
                                    )
                                    .opacity(isSelf ? 0.6 : 1.0)
                                }
                                .buttonStyle(.plain)
                                .disabled(state.hasVoted || isSelf)
                            }
                        }

                        // Skip Vote & Submit Section
                        if !state.hasVoted {
                            VStack(spacing: 24) {
                                Button {
                                    withAnimation(.quickSpring) {
                                        skipVote.toggle()
                                        if skipVote { selectedIds.removeAll() }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: skipVote ? "xmark.circle.fill" : "circle")
                                        Text("SKIP VOTE (NOBODY IS SUSPICIOUS)")
                                            .font(.appCaption)
                                            .tracking(1)
                                    }
                                    .foregroundColor(skipVote ? .appDestructive : .appMutedForeground.opacity(0.6))
                                }

                                PillButton(
                                    title: selectedIds.count > 1
                                        ? "SUBMIT \(selectedIds.count) VOTES"
                                        : "SUBMIT VOTE",
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
                            .scaledPadding(.all, 32.0)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                            .premiumShadow()
                        } else {
                            VStack(spacing: 16) {
                                WaitingIndicator(message: "WAITING FOR OTHERS (\(state.votedCount)/\(players.count))")
                                
                                Button(action: {
                                    Task { await viewModel.refreshState() }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("STUCK? REFRESH")
                                    }
                                    .font(.system(size: ScreenScale.font(12), weight: .medium))
                                    .foregroundColor(.appPrimary.opacity(0.6))
                                }
                                .scaledPadding(.top, 20.0)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .scaledPadding(.horizontal, 32.0)
                }
                
                // Top Right Controls (Absolute Positioned)
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
                                .font(.system(size: ScreenScale.font(14), weight: .medium))
                                .foregroundColor(.black.opacity(0.3))
                                .scaledPadding(.all, 10.0)
                                .background(Color.black.opacity(0.04))
                                .clipShape(Circle())
                        }
                        .scaledPadding(.trailing, 20.0)
                        .scaledPadding(.top, 20.0)
                    }
                    Spacer()
                }
            }
        }
    }
}
