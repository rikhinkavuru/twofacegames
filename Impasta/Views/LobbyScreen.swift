import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LobbyScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) private var theme

    @State private var showSettings = false
    @State private var showCopiedFeedback = false
    @State private var lobbyTimer: Timer?

    @State private var localDifficulty: Difficulty = .medium
    @State private var localClueRounds: Int = 1
    @State private var localImposterRandom: Bool = false
    @State private var localImposterCount: Int = 1
    @State private var localImposterMin: Int = 1
    @State private var localImposterMax: Int = 1

    private var players: [Player] { viewModel.players }
    private var isHost: Bool { viewModel.isHost }

    private var playerColumns: [GridItem] {
        [GridItem(.adaptive(minimum: ScreenScale.width(156), maximum: .infinity), spacing: ScreenScale.width(14))]
    }

    var body: some View {
        ZStack {
            LobbyAmbientBackground()

            if let game = viewModel.game {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ScreenScale.height(18)) {
                        headerCard(game: game)
                        playersSection
                    }
                    .padding(.horizontal, ScreenScale.width(20))
                    .padding(.top, ScreenScale.height(18))
                    .padding(.bottom, ScreenScale.height(showSettings && isHost ? 340 : 200))
                }
                .safeAreaInset(edge: .bottom) {
                    bottomControls
                        .padding(.horizontal, ScreenScale.width(16))
                        .padding(.bottom, ScreenScale.height(12))
                }
                .onAppear {
                    syncLocalState(with: game)
                    startLobbyTimer()
                }
                .onDisappear {
                    stopLobbyTimer()
                }
                .onChange(of: viewModel.game) { _, newGame in
                    guard let newGame else { return }
                    syncLocalState(with: newGame)
                }
            }
        }
        .animation(.smoothSpring, value: showSettings)
    }

    private func headerCard(game: Game) -> some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(18)) {
            HStack(alignment: .top, spacing: ScreenScale.width(12)) {
                VStack(alignment: .leading, spacing: ScreenScale.height(8)) {
                    Text("Live Lobby")
                        .font(.system(size: ScreenScale.font(11), weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentSecondary)
                        .tracking(2.8)

                    Text("Keep the room locked in.")
                        .font(.system(size: ScreenScale.font(28), weight: .black, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(isHost ? "Tune settings, manage players, then launch when everyone is ready." : "Share the code, watch the roster fill up, and wait for the host to launch.")
                        .font(.system(size: ScreenScale.font(14), weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button {
                    viewModel.exitGame()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: ScreenScale.font(18), weight: .bold))
                        .foregroundColor(theme.textPrimary)
                        .padding(14)
                        .background(theme.surfaceElevated.opacity(0.95))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(theme.border.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            VStack(alignment: .leading, spacing: ScreenScale.height(14)) {
                Text("Game Code")
                    .font(.system(size: ScreenScale.font(11), weight: .bold, design: .rounded))
                    .foregroundColor(theme.textSecondary.opacity(0.88))
                    .tracking(2.4)

                HStack(spacing: ScreenScale.width(12)) {
                    Text(game.code)
                        .font(.system(size: ScreenScale.font(34), weight: .black, design: .monospaced))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.textPrimary, theme.accent, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        copyCode(game.code)
                    } label: {
                        VStack(spacing: ScreenScale.height(4)) {
                            Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                .font(.system(size: ScreenScale.font(18), weight: .bold))
                            Text(showCopiedFeedback ? "Copied" : "Copy")
                                .font(.system(size: ScreenScale.font(10), weight: .bold, design: .rounded))
                                .tracking(1.2)
                        }
                        .foregroundColor(showCopiedFeedback ? theme.success : theme.textPrimary)
                        .padding(.horizontal, ScreenScale.width(14))
                        .padding(.vertical, ScreenScale.height(10))
                        .background((showCopiedFeedback ? theme.success : theme.accent).opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke((showCopiedFeedback ? theme.success : theme.accent).opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .if(showCopiedFeedback) { view in
                        view.neonGlow(color: theme.success)
                    }
                }
                .padding(.horizontal, ScreenScale.width(18))
                .padding(.vertical, ScreenScale.height(18))
                .frame(maxWidth: .infinity)
                .background(theme.surfaceElevated.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(theme.border.opacity(0.75), lineWidth: 1)
                )
                .neonGlow(color: theme.accent)
            }

            HStack(spacing: ScreenScale.width(12)) {
                statPill(title: "Players", value: "\(players.count)", accent: theme.civilian)
                statPill(title: "Host", value: isHost ? "You" : "Remote", accent: theme.host)
                statPill(title: "Start", value: players.count >= 3 ? "Ready" : "Need 3", accent: players.count >= 3 ? theme.success : theme.warning)
            }
        }
        .padding(.horizontal, ScreenScale.width(20))
        .padding(.vertical, ScreenScale.height(22))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.border.opacity(0.65), lineWidth: 1)
        )
        .premiumShadow()
    }

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(14)) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: ScreenScale.height(6)) {
                    Text("Players")
                        .font(.system(size: ScreenScale.font(24), weight: .black, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Text("\(players.count) connected to the lobby")
                        .font(.system(size: ScreenScale.font(13), weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }

            LazyVGrid(columns: playerColumns, spacing: ScreenScale.height(14)) {
                ForEach(players) { player in
                    playerCard(player)
                }
            }
        }
    }

    private func playerCard(_ player: Player) -> some View {
        let accent = player.isHost ? theme.host : (player.id == viewModel.currentPlayerId ? theme.accent : theme.accentSecondary)

        return VStack(alignment: .leading, spacing: ScreenScale.height(14)) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.16))
                        .scaledFrame(width: 44, height: 44)
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: ScreenScale.font(18), weight: .black, design: .rounded))
                        .foregroundColor(accent)
                }
                .if(player.isHost || player.id == viewModel.currentPlayerId) { view in
                    view.neonGlow(color: accent)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: ScreenScale.height(6)) {
                    if player.isHost {
                        badge(title: "HOST", color: theme.host, icon: "crown.fill")
                    }
                    if player.id == viewModel.currentPlayerId {
                        badge(title: "YOU", color: theme.accent, icon: "person.fill")
                    }
                }
            }

            VStack(alignment: .leading, spacing: ScreenScale.height(6)) {
                Text(player.name)
                    .font(.system(size: ScreenScale.font(18), weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)

                Text(player.isHost ? "Controls lobby settings" : "Ready in the queue")
                    .font(.system(size: ScreenScale.font(12), weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
            }

            if isHost && !player.isHost {
                Button {
                    Task { await viewModel.kickPlayer(playerId: player.id) }
                } label: {
                    HStack(spacing: ScreenScale.width(8)) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: ScreenScale.font(14), weight: .bold))
                        Text("Remove")
                            .font(.system(size: ScreenScale.font(12), weight: .bold, design: .rounded))
                            .tracking(0.8)
                    }
                    .foregroundColor(theme.destructive)
                    .padding(.horizontal, ScreenScale.width(12))
                    .padding(.vertical, ScreenScale.height(10))
                    .background(theme.destructive.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(theme.destructive.opacity(0.32), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, ScreenScale.width(16))
        .padding(.vertical, ScreenScale.height(16))
        .frame(maxWidth: .infinity, minHeight: ScreenScale.height(160), alignment: .topLeading)
        .background(theme.surface.opacity(player.id == viewModel.currentPlayerId ? 0.86 : 0.76))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke((player.id == viewModel.currentPlayerId ? theme.accent : accent).opacity(0.32), lineWidth: 1)
        )
        .shadow(color: accent.opacity(player.id == viewModel.currentPlayerId ? 0.22 : 0.12), radius: 18, x: 0, y: 10)
    }

    private var bottomControls: some View {
        VStack(spacing: ScreenScale.height(14)) {
            if isHost {
                HStack(spacing: ScreenScale.width(12)) {
                    Button {
                        #if canImport(UIKit)
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        #endif
                        withAnimation(.smoothSpring) {
                            showSettings.toggle()
                        }
                    } label: {
                        HStack(spacing: ScreenScale.width(10)) {
                            Image(systemName: "slider.horizontal.3")
                            Text(showSettings ? "Hide Settings" : "Show Settings")
                            Image(systemName: showSettings ? "chevron.down" : "chevron.up")
                        }
                        .font(.system(size: ScreenScale.font(13), weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ScreenScale.height(16))
                        .background(theme.surfaceElevated.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(theme.border.opacity(0.65), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                if showSettings {
                    settingsPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                primaryStartButton

                if players.count < 3 {
                    Text("Need at least 3 players to start")
                        .font(.system(size: ScreenScale.font(12), weight: .bold, design: .rounded))
                        .foregroundColor(theme.warning)
                        .tracking(0.4)
                }
            } else {
                VStack(spacing: ScreenScale.height(10)) {
                    WaitingIndicator(message: "Waiting for host to start")
                    Text("The host can adjust settings and launch once the room is ready.")
                        .font(.system(size: ScreenScale.font(12), weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, ScreenScale.width(18))
                .padding(.vertical, ScreenScale.height(18))
                .background(theme.surface.opacity(0.76))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(theme.border.opacity(0.65), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, ScreenScale.width(14))
        .padding(.vertical, ScreenScale.height(14))
        .frame(maxWidth: .infinity)
        .background(theme.surface.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.border.opacity(0.65), lineWidth: 1)
        )
        .premiumShadow()
    }

    private var settingsPanel: some View {
        VStack(spacing: ScreenScale.height(18)) {
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
                VStack(spacing: ScreenScale.height(14)) {
                    Toggle(isOn: Binding(
                        get: { localImposterRandom },
                        set: { newValue in
                            localImposterRandom = newValue
                            updateSettings()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: ScreenScale.height(4)) {
                            Text("Randomize Count")
                                .font(.system(size: ScreenScale.font(14), weight: .bold, design: .rounded))
                                .foregroundColor(theme.textPrimary)
                            Text("Let the lobby draw a range of possible imposters.")
                                .font(.system(size: ScreenScale.font(11), weight: .medium, design: .rounded))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .tint(theme.accent)
                    .padding(.horizontal, ScreenScale.width(16))
                    .padding(.vertical, ScreenScale.height(14))
                    .background(theme.surfaceElevated.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    if localImposterRandom {
                        HStack(spacing: ScreenScale.width(12)) {
                            StepperField(
                                label: "Min",
                                value: Binding(
                                    get: { localImposterMin },
                                    set: { newMin in
                                        localImposterMin = newMin
                                        if localImposterMax < newMin {
                                            localImposterMax = newMin
                                        }
                                        updateSettings()
                                    }
                                ),
                                range: 0...max(1, players.count - 1)
                            )

                            StepperField(
                                label: "Max",
                                value: Binding(
                                    get: { localImposterMax },
                                    set: { newMax in
                                        localImposterMax = newMax
                                        if localImposterMin > newMax {
                                            localImposterMin = newMax
                                        }
                                        updateSettings()
                                    }
                                ),
                                range: localImposterMin...max(1, players.count - 1)
                            )
                        }
                    } else {
                        StepperField(
                            label: "Count",
                            value: Binding(
                                get: { localImposterCount },
                                set: { newCount in
                                    localImposterCount = newCount
                                    localImposterMin = newCount
                                    localImposterMax = newCount
                                    updateSettings()
                                }
                            ),
                            range: 0...max(1, players.count - 1)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, ScreenScale.width(16))
        .padding(.vertical, ScreenScale.height(18))
        .background(theme.surface.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border.opacity(0.6), lineWidth: 1)
        )
    }

    private var primaryStartButton: some View {
        Button {
            #if canImport(UIKit)
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            #endif
            Task { await viewModel.startGame() }
        } label: {
            HStack(spacing: ScreenScale.width(10)) {
                Image(systemName: "play.fill")
                Text("Start Game")
                    .tracking(1.2)
                Image(systemName: "sparkles")
            }
            .font(.system(size: ScreenScale.font(15), weight: .black, design: .rounded))
            .foregroundColor(players.count < 3 ? theme.textSecondary : theme.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ScreenScale.height(18))
            .background(
                LinearGradient(
                    colors: players.count < 3
                        ? [theme.surfaceElevated, theme.surfaceElevated]
                        : [theme.accent, theme.accentSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(players.count < 3 ? theme.border.opacity(0.65) : Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .disabled(players.count < 3)
        .buttonStyle(ScaleButtonStyle())
        .if(players.count >= 3) { view in
            view.neonGlow(color: theme.accent)
        }
    }

    private func statPill(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(6)) {
            Text(title.uppercased())
                .font(.system(size: ScreenScale.font(9), weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)
                .tracking(1.6)
            Text(value)
                .font(.system(size: ScreenScale.font(14), weight: .black, design: .rounded))
                .foregroundColor(theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ScreenScale.width(12))
        .padding(.vertical, ScreenScale.height(12))
        .background(accent.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.24), lineWidth: 1)
        )
    }

    private func badge(title: String, color: Color, icon: String) -> some View {
        HStack(spacing: ScreenScale.width(6)) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: ScreenScale.font(10), weight: .bold, design: .rounded))
        .foregroundColor(color)
        .padding(.horizontal, ScreenScale.width(10))
        .padding(.vertical, ScreenScale.height(6))
        .background(color.opacity(0.14))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
    }

    private func copyCode(_ code: String) {
        copyToClipboard(text: code)
        #if canImport(UIKit)
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        #endif
        #endif

        withAnimation(.smoothSpring) {
            showCopiedFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.smoothSpring) {
                showCopiedFeedback = false
            }
        }
    }

    private func syncLocalState(with game: Game) {
        localDifficulty = game.difficultyEnum
        localClueRounds = game.clueRounds
        localImposterRandom = game.imposterRandom
        localImposterCount = game.imposterCount
        localImposterMin = game.imposterMin
        localImposterMax = game.imposterMax
    }

    @MainActor
    private func startLobbyTimer() {
        stopLobbyTimer()
        let currentViewModel = viewModel
        lobbyTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            Task { @MainActor in
                guard currentViewModel.game?.phase == .lobby else {
                    timer.invalidate()
                    return
                }
                await currentViewModel.refreshState()
            }
        }
    }

    @MainActor
    private func stopLobbyTimer() {
        lobbyTimer?.invalidate()
        lobbyTimer = nil
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
    @Environment(\.theme) private var theme

    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(12)) {
            Text(label.uppercased())
                .font(.system(size: ScreenScale.font(10), weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)
                .tracking(1.8)

            HStack(spacing: ScreenScale.width(14)) {
                stepButton(icon: "minus", enabled: value > range.lowerBound) {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }

                Text("\(value)")
                    .font(.system(size: ScreenScale.font(18), weight: .black, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity)

                stepButton(icon: "plus", enabled: value < range.upperBound) {
                    if value < range.upperBound {
                        value += 1
                    }
                }
            }
        }
        .padding(.horizontal, ScreenScale.width(14))
        .padding(.vertical, ScreenScale.height(14))
        .frame(maxWidth: .infinity)
        .background(theme.surfaceElevated.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.border.opacity(0.6), lineWidth: 1)
        )
    }

    private func stepButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "\(icon).circle.fill")
                .font(.system(size: ScreenScale.font(20), weight: .bold))
                .foregroundColor(enabled ? theme.accent : theme.border)
                .neonGlow(color: enabled ? theme.accent : .clear)
        }
        .disabled(!enabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct LobbyAmbientBackground: View {
    @Environment(\.theme) private var theme
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.background, theme.surfaceElevated.opacity(0.9), theme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                Circle()
                    .fill(glow(colors: [theme.accent.opacity(0.4), theme.accentSecondary.opacity(0.14), .clear]))
                    .frame(width: width * 0.9, height: width * 0.9)
                    .blur(radius: 26)
                    .offset(x: animate ? width * 0.22 : -width * 0.14, y: animate ? -height * 0.22 : -height * 0.32)

                Circle()
                    .fill(glow(colors: [theme.success.opacity(0.28), theme.civilian.opacity(0.18), .clear]))
                    .frame(width: width * 0.72, height: width * 0.72)
                    .blur(radius: 22)
                    .offset(x: animate ? -width * 0.18 : width * 0.14, y: animate ? height * 0.22 : height * 0.06)

                Circle()
                    .fill(glow(colors: [theme.host.opacity(0.24), theme.accent.opacity(0.14), .clear]))
                    .frame(width: width * 0.46, height: width * 0.46)
                    .blur(radius: 14)
                    .offset(x: animate ? width * 0.14 : -width * 0.04, y: animate ? height * 0.56 : height * 0.4)
            }
            .ignoresSafeArea()

            Rectangle()
                .fill(.black.opacity(0.08))
                .blendMode(.overlay)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func glow(colors: [Color]) -> RadialGradient {
        RadialGradient(colors: colors, center: .center, startRadius: 16, endRadius: 220)
    }
}
