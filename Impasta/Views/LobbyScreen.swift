import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LobbyScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showSettings = false
    @State private var showCopiedFeedback = false
    @State private var lobbyTimer: Timer?
    
    // Local state for settings to ensure immediate UI feedback
    @State private var localDifficulty: Difficulty = .medium
    @State private var localClueRounds: Int = 1
    @State private var localImposterRandom: Bool = false
    @State private var localImposterCount: Int = 1
    @State private var localImposterMin: Int = 1
    @State private var localImposterMax: Int = 1

    private var players: [Player] { viewModel.players }
    private var isHost: Bool { viewModel.isHost }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if let game = viewModel.game {
                VStack(spacing: 0) {
                    // Header (Left Aligned)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("GAME CODE")
                                    .font(.system(size: ScreenScale.font(11), weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                                    .tracking(3)
                                    .scaledFrame(height: 34)

                                Text(game.code)
                                    .font(.system(size: ScreenScale.font(32), weight: .bold, design: .monospaced))
                                    .tracking(8)
                                    .foregroundColor(.black)
                                    .scaledPadding(.top, 4.0)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                // Copy Button
                                Button {
                                    copyToClipboard(text: game.code)
                                    // Add haptic feedback
                                    #if canImport(UIKit)
                                    #if os(iOS)
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.prepare()
                                    impactFeedback.impactOccurred()
                                    #endif
                                    #endif
                                    withAnimation {
                                        showCopiedFeedback = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showCopiedFeedback = false
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                        if showCopiedFeedback {
                                            Text("COPIED")
                                                .font(.system(size: ScreenScale.font(10), weight: .medium))
                                        }
                                    }
                                    .scaledPadding(.horizontal, 12.0)
                                    .scaledPadding(.vertical, 8.0)
                                    .background(showCopiedFeedback ? Color.appSoftSage.opacity(0.1) : Color.appSoftIndigo.opacity(0.1))
                                    .foregroundColor(showCopiedFeedback ? .appSoftSage : .appSoftIndigo)
                                    .clipShape(Capsule())
                                }
                                
                                // Return Home Button
                                Button {
                                    viewModel.exitGame()
                                } label: {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: ScreenScale.font(18)))
                                        .foregroundColor(.black.opacity(0.5))
                                        .scaledPadding(.all, 8.0)
                                        .background(Color.black.opacity(0.05))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        Text("PLAYERS (\(players.count))")
                            .font(.system(size: ScreenScale.font(11), weight: .medium))
                            .foregroundColor(.black.opacity(0.3))
                            .tracking(3)
                            .scaledPadding(.top, 40.0)
                    }
                    .scaledPadding(.horizontal, 32.0)
                    .scaledPadding(.top, 20.0)
                    .scaledPadding(.bottom, 20.0)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Player List
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(players) { player in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(player.isHost ? Color.appSoftAmber.opacity(0.15) : Color.appSoftIndigo.opacity(0.1))
                                            .scaledFrame(width: 32, height: 32)
                                            .overlay(
                                                Text(String(player.name.prefix(1)).uppercased())
                                                    .font(.system(size: ScreenScale.font(14), weight: .medium))
                                                    .foregroundColor(player.isHost ? .appSoftAmber : .appSoftIndigo)
                                            )

                                        Text(player.name)
                                            .font(.system(size: ScreenScale.font(15), weight: .medium))
                                            .foregroundColor(.black)
                                            .lineLimit(1)

                                        if player.isHost {
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: ScreenScale.font(10)))
                                                .foregroundColor(.appSoftAmber)
                                        }
                                        
                                        Spacer()
                                        
                                        // Kick button (host only, can't kick self)
                                        if isHost && !player.isHost {
                                            Button {
                                                Task { await viewModel.kickPlayer(playerId: player.id) }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: ScreenScale.font(16)))
                                                    .foregroundColor(.appDestructive.opacity(0.5))
                                            }
                                        }
                                    }
                                    .scaledPadding(.all, 16.0)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .premiumShadow()
                                }
                            }
                            .scaledPadding(.horizontal, 32.0)
                        }
                    }

                    // Bottom Controls Area
                    VStack(spacing: 0) {
                        if isHost {
                            // Settings Toggle Button
                            Button {
                                // Add haptic feedback
                                #if canImport(UIKit)
                                #if os(iOS)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred()
                                #endif
                                #endif
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showSettings.toggle() }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundColor(.appSoftIndigo)
                                    Text("SETTINGS")
                                    Image(systemName: showSettings ? "chevron.down" : "chevron.up")
                                }
                                .font(.system(size: ScreenScale.font(11), weight: .medium))
                                .foregroundColor(.black.opacity(0.5))
                                .tracking(3)
                            }
                            .frame(maxWidth: .infinity)
                            .scaledFrame(height: 60)
                            .background(Color.white)
                            
                            if showSettings {
                                settingsPanel
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            // Start Button
                            Button {
                                // Add haptic feedback
                                #if canImport(UIKit)
                                #if os(iOS)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred()
                                #endif
                                #endif
                                Task { await viewModel.startGame() }
                            } label: {
                                HStack(spacing: 12) {
                                    Text("START GAME")
                                        .font(.system(size: ScreenScale.font(14), weight: .medium))
                                        .tracking(1)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: ScreenScale.font(16)))
                                }
                                .frame(maxWidth: .infinity)
                                .scaledPadding(.vertical, 20.0)
                                .background(players.count < 3 ? Color.black.opacity(0.1) : Color.black)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                            }
                            .disabled(players.count < 3)
                            .scaledPadding(.horizontal, 32.0)
                            .scaledPadding(.bottom, 20.0)
                            
                            if players.count < 3 {
                                Text("Need at least 3 players to start")
                                    .font(.system(size: ScreenScale.font(10), weight: .medium))
                                    .foregroundColor(.appDestructive.opacity(0.6))
                                    .scaledPadding(.bottom, 20.0)
                            }
                        } else {
                            WaitingIndicator(message: "Waiting for host to start")
                                .scaledPadding(.vertical, 20.0)
                        }
                    }
                    .background(Color.white)
                }
                .onAppear {
                    localDifficulty = game.difficultyEnum
                    localClueRounds = game.clueRounds
                    localImposterRandom = game.imposterRandom
                    localImposterCount = game.imposterCount
                    localImposterMin = game.imposterMin
                    localImposterMax = game.imposterMax
                    
                    // Periodic refresh to ensure lobby stays synced
                    lobbyTimer?.invalidate()
                    lobbyTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                        Task { @MainActor in
                            if game.phase == .lobby {
                                await viewModel.refreshState()
                            } else {
                                timer.invalidate()
                            }
                        }
                    }
                }
                .onDisappear {
                    lobbyTimer?.invalidate()
                    lobbyTimer = nil
                }
            }
        }
    }

    private var settingsPanel: some View {
        VStack(spacing: 20) {
            SettingsRow(label: "Difficulty") {
                AppSegmentedControl(
                    options: Difficulty.allCases,
                    selected: Binding(
                        get: { localDifficulty },
                        set: { newDifficulty in
                            localDifficulty = newDifficulty
                            updateSettings()
                        }
                    )
                ) { difficulty in
                    AnyView(
                        HStack(spacing: 6) {
                            Image(systemName: difficulty.iconName)
                            Text(difficulty.label)
                        }
                    )
                }
            }

            SettingsRow(label: "Clue Rounds") {
                AppSegmentedControl(
                    options: [1, 2, 3],
                    selected: Binding(
                        get: { localClueRounds },
                        set: { newRounds in
                            localClueRounds = newRounds
                            updateSettings()
                        }
                    )
                ) { rounds in
                    AnyView(
                        HStack(spacing: 6) {
                            Image(systemName: "message.fill")
                            Text("\(rounds)")
                        }
                    )
                }
            }

            SettingsRow(label: "Imposters") {
                VStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { localImposterRandom },
                        set: { newValue in
                            localImposterRandom = newValue
                            updateSettings()
                        }
                    )) {
                        Text("Randomize Count")
                            .font(.system(size: ScreenScale.font(13), weight: .medium))
                    }
                    .tint(.appSoftIndigo)

                    if localImposterRandom {
                        HStack(spacing: 12) {
                            StepperField(label: "Min", value: Binding(
                                get: { localImposterMin },
                                set: { newMin in 
                                    localImposterMin = newMin
                                    // Ensure max is at least min
                                    if localImposterMax < newMin {
                                        localImposterMax = newMin
                                    }
                                    updateSettings()
                                }
                            ), range: 0...max(1, players.count - 1))
                            StepperField(label: "Max", value: Binding(
                                get: { localImposterMax },
                                set: { newMax in 
                                    localImposterMax = newMax
                                    // Ensure min is at most max
                                    if localImposterMin > newMax {
                                        localImposterMin = newMax
                                    }
                                    updateSettings()
                                }
                            ), range: localImposterMin...max(1, players.count - 1))
                        }
                    } else {
                        StepperField(label: "Count", value: Binding(
                            get: { localImposterCount },
                            set: { newCount in 
                                localImposterCount = newCount
                                localImposterMin = newCount
                                localImposterMax = newCount
                                updateSettings()
                            }
                        ), range: 0...max(1, players.count - 1))
                    }
                }
            }
        }
        .scaledPadding(.all, 24.0)
        .background(Color.appSecondary.opacity(0.5))
    }

    private func updateSettings() {
        let settings = GameSettings(
            difficulty: localDifficulty,
            imposterRandom: localImposterRandom,
            imposterMin: localImposterMin,
            imposterMax: localImposterMax,
            clueRounds: localClueRounds
        )
        Task { await viewModel.updateSettings(settings) }
    }

    private func copyToClipboard(text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #else
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

struct StepperField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: ScreenScale.font(12), weight: .medium))
            Spacer()
            HStack(spacing: 15) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(value > range.lowerBound ? .appSoftIndigo : .black.opacity(0.1))
                    .onTapGesture {
                        if value > range.lowerBound {
                            value -= 1
                        }
                    }
                
                Text("\(value)")
                    .font(.system(size: ScreenScale.font(14), weight: .medium))
                    .frame(width: 20)
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(value < range.upperBound ? .appSoftIndigo : .black.opacity(0.1))
                    .onTapGesture {
                        if value < range.upperBound {
                            value += 1
                        }
                    }
            }
        }
        .scaledPadding(.all, 12.0)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
