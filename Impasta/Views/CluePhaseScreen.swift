import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CluePhaseScreen: View {
    @ObservedObject var viewModel: GameViewModel

    @State private var clue = ""

    private var players: [Player] { viewModel.players }
    
    // MARK: - Computed Properties for Clue State
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
            Color.appBackground.ignoresSafeArea()

            if let state = clueState {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header (Centered)
                        VStack(spacing: 16) {
                            Text("CLUE ROUND \(state.clueRoundState.currentRound) / \(state.game.clueRounds)")
                                .font(.appCaption)
                                .foregroundColor(.appMutedForeground.opacity(0.6))
                                .tracking(3)

                            Text(state.isMyTurn && !state.hasSubmitted
                                 ? "IT'S YOUR TURN"
                                 : state.clueRoundState.activePlayer != nil
                                 ? "WAITING FOR \(state.clueRoundState.activePlayer!.name.uppercased())"
                                 : "WAITING...")
                                .font(.system(size: ScreenScale.font(22), weight: .medium))
                                .tracking(-0.5)
                                .foregroundColor(.appForeground)
                                .multilineTextAlignment(.center)

                            Text("One word only. Be subtle.")
                                .font(.system(size: ScreenScale.font(12), weight: .medium))
                                .foregroundColor(.appMutedForeground.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .scaledPadding(.top, 40.0)
                        .scaledPadding(.bottom, 32.0)

                        // Turn list
                        VStack(spacing: 12) {
                            ForEach(Array(state.clueRoundState.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                                let isActive = index == state.clueRoundState.turnInRound
                                let isDone = index < state.clueRoundState.turnInRound ||
                                    (isActive && hasClueForRound(player.clue, round: state.clueRoundState.currentRound))
                                let latestClue = parseClues(player.clue).last

                                HStack(spacing: 16) {
                                    // Number / Check
                                    Circle()
                                        .fill(
                                            isActive ? Color.white :
                                            isDone ? Color.appPrimary.opacity(0.1) :
                                            Color.appSecondary
                                        )
                                        .scaledFrame(width: 32, height: 32)
                                        .overlay(
                                            Group {
                                                if isDone {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: ScreenScale.font(12), weight: .medium))
                                                        .foregroundColor(.appPrimary)
                                                } else {
                                                    Text("\(index + 1)")
                                                        .font(.system(size: ScreenScale.font(10), weight: .medium))
                                                        .foregroundColor(
                                                            isActive ? .appPrimary : .appMutedForeground
                                                        )
                                                }
                                            }
                                        )

                                    // Name
                                    HStack(spacing: 4) {
                                        Text(player.name)
                                            .font(.system(size: ScreenScale.font(14), weight: .medium))
                                            .tracking(-0.3)
                                            .foregroundColor(
                                                isActive ? .white : .appForeground
                                            )

                                        if player.id == state.currentPlayer.id {
                                            Text("YOU")
                                                .font(.system(size: ScreenScale.font(10), weight: .medium))
                                                .foregroundColor(
                                                    isActive ? .white.opacity(0.6) : .appMutedForeground.opacity(0.6)
                                                )
                                        }
                                    }

                                    Spacer()

                                    // Clue
                                    if let latestClue = latestClue {
                                        Text("\u{201C}\(latestClue)\u{201D}")
                                            .font(.system(size: ScreenScale.font(14), weight: .medium))
                                            .tracking(-0.3)
                                            .foregroundColor(isActive ? .white : .appForeground)
                                            .textCase(.uppercase)
                                    }
                                }
                                .scaledPadding(.horizontal, 24.0)
                                .scaledPadding(.vertical, 16.0)
                                .background(
                                    isActive ? Color.appPrimary :
                                    isDone ? Color.white :
                                    Color.white.opacity(0.4)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(
                                            isActive ? Color.clear :
                                            isDone ? Color.appBorder.opacity(0.3) :
                                            Color.appBorder.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                                .if(isActive) { view in
                                    view.accentGlow()
                                }
                                .if(isDone) { view in
                                    view.premiumShadow().opacity(0.6)
                                }
                                .scaleEffect(isActive ? 1.02 : 1.0)
                                .animation(.smoothSpring, value: isActive)
                            }
                        }
                        .scaledPadding(.horizontal, 24.0)
                        .scaledPadding(.bottom, 24.0)

                        // Input area
                        if state.isMyTurn && !state.hasSubmitted {
                            VStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("YOUR CLUE")
                                        .font(.appCaption)
                                        .foregroundColor(.appMutedForeground.opacity(0.6))
                                        .tracking(3)

                                    TextField("TYPE WORD...", text: $clue)
                                        .font(.system(size: ScreenScale.font(28), weight: .medium))
                                        .tracking(-1)
                                        .foregroundColor(.appForeground)
                                        #if os(iOS)
                                        .textInputAutocapitalization(.characters)
                                        #endif
                                        .autocorrectionDisabled()
                                        .scaledPadding(.vertical, 16.0)
                                        .scaledPadding(.horizontal, 24.0)
                                        .overlay(
                                            Rectangle()
                                                .scaledFrame(height: 1)
                                                .foregroundColor(.appBorder),
                                            alignment: .bottom
                                        )
                                        .onChange(of: clue) { _, newValue in
                                            // Remove spaces (one word only)
                                            clue = newValue.replacingOccurrences(of: " ", with: "")
                                            if clue.count > 30 { clue = String(clue.prefix(30)) }
                                        }
                                        .onSubmit { submitClue() }
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
                            .scaledPadding(.all, 24.0)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .premiumShadow()
                            .overlay(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
                            )
                            .transition(.scale.combined(with: .opacity))
                            .scaledPadding(.horizontal, 24.0)
                            .scaledPadding(.bottom, 32.0)
                        }

                        // Waiting indicator
                        if !state.isMyTurn || state.hasSubmitted {
                            VStack(spacing: 16) {
                                WaitingIndicator()
                                
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
                            }
                            .scaledPadding(.bottom, 40.0)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .onChange(of: state.game.currentTurnIndex) { _, _ in
                    clue = ""
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

    private func submitClue() {
        let trimmed = clue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { await viewModel.submitClue(trimmed) }
    }
}
