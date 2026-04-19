import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RoleRevealScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var isFlipped = false
    @State private var showControls = false

    private var isHost: Bool { viewModel.isHost }

    var body: some View {
        ZStack {
            if let game = viewModel.game, let currentPlayer = viewModel.currentPlayer {
                let isImposter = currentPlayer.isImposter
                
                (isFlipped && isImposter ? Color.appSoftRose.opacity(0.04) : Color.appBackground)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0), value: isFlipped)

                VStack(spacing: 0) {
                    // Header (Centered)
                    VStack(spacing: 16) {
                        Text("SECRET ROLE")
                            .font(.appCaption)
                            .foregroundColor(.appMutedForeground.opacity(0.6))
                            .tracking(3)

                        Text(isFlipped
                             ? (isImposter ? "YOU ARE THE IMPOSTER" : "YOU ARE A CIVILIAN")
                             : "REVEAL YOUR IDENTITY")
                            .font(.system(size: ScreenScale.font(22), weight: .medium))
                            .tracking(-0.5)
                            .foregroundColor(.appForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .scaledPadding(.top, 60.0)
                    
                    Spacer(minLength: 40)

                    // 3D Flip Card (Centered)
                    flipCard(game: game, currentPlayer: currentPlayer)
                        .scaledFrame(height: 380)
                        .scaledPadding(.horizontal, 32.0)
                        .onTapGesture {
                            guard !isFlipped else { return }
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                                isFlipped = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showControls = true
                                }
                            }
                        }
                    
                    Spacer(minLength: 40)

                    // Controls (Bottom)
                    if showControls {
                        controlsView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .scaledPadding(.bottom, 40.0)
                    } else {
                        Spacer(minLength: 40)
                    }
                }
                .scaledPadding(.horizontal, 32.0)
                
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
                        .scaledPadding(.top, 60.0)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Controls View
    private var controlsView: some View {
        Group {
            if isHost {
                VStack(spacing: 16) {
                    Button(action: {
                        Task { await viewModel.proceedToClues() }
                    }) {
                        HStack(spacing: 12) {
                            Text("EVERYONE READY")
                                .font(.system(size: ScreenScale.font(14), weight: .medium))
                                .tracking(1)

                            Image(systemName: "chevron.right")
                                .font(.system(size: ScreenScale.font(16), weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .scaledPadding(.vertical, 20.0)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    WaitingIndicator(message: "Waiting for host")

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
                    .scaledPadding(.top, 60.0)
                }
            }
        }
    }

    // MARK: - Flip Card
    private func flipCard(game: Game, currentPlayer: Player) -> some View {
        ZStack {
            // Front
            frontCard
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            // Back
            backCard(game: game, currentPlayer: currentPlayer)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
    }

    private var frontCard: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.appSoftLavender.opacity(0.1))
                    .scaledFrame(width: 96, height: 96)

                Circle()
                    .fill(Color.appSoftIndigo.opacity(0.1))
                    .scaledFrame(width: 64, height: 64)

                Circle()
                    .fill(Color.appSoftIndigo)
                    .scaledFrame(width: 32, height: 32)
            }

            Text("TAP TO FLIP")
                .font(.system(size: ScreenScale.font(14), weight: .medium))
                .foregroundColor(.appMutedForeground.opacity(0.6))
                .tracking(-0.3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
        .premiumShadow()
        .overlay(
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private func backCard(game: Game, currentPlayer: Player) -> some View {
        let isImposter = currentPlayer.isImposter
        return VStack(spacing: 32) {
            Circle()
                .fill(isImposter ? Color(hex: "FFB3BA").opacity(0.4) : Color(hex: "A8E6C1").opacity(0.4))
                .scaledFrame(width: 96, height: 96)
                .overlay(
                    Image(systemName: isImposter ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: ScreenScale.font(40)))
                        .foregroundColor(isImposter ? Color(hex: "D32F2F") : Color(hex: "00796B"))
                )

            VStack(spacing: 16) {
                Text(isImposter ? "YOUR CLUE" : "THE SECRET WORD")
                    .font(.appCaption)
                    .foregroundColor(.appMutedForeground.opacity(0.6))
                    .tracking(3)

                Text((isImposter ? game.imposterClue : game.word) ?? "")
                    .font(.system(size: ScreenScale.font(44), weight: .medium))
                    .tracking(-2)
                    .foregroundColor(isImposter ? Color(hex: "D32F2F") : Color(hex: "00796B"))
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
            }

            if isImposter {
                Text("Blend in. Give clues that sound like you know the word.")
                    .font(.system(size: ScreenScale.font(12), weight: .medium))
                    .foregroundColor(.appMutedForeground.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
        .premiumShadow()
        .overlay(
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .stroke(
                    isImposter ? Color(hex: "D32F2F").opacity(0.3) : Color(hex: "00796B").opacity(0.3),
                    lineWidth: 2
                )
        )
    }
}
