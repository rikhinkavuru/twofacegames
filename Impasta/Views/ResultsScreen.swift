import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ResultsScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) private var theme

    @State private var showConfetti = false
    @State private var showRedBorder = false
    @State private var animateBackdrop = false

    private var players: [Player] { viewModel.players }
    private var isHost: Bool { viewModel.isHost }

    private var resultsData: ResultsData? {
        guard let game = viewModel.game, let _ = viewModel.currentPlayer else { return nil }

        let imposters = players.filter { $0.isImposter }
        let imposterIds = Set(imposters.map { $0.id })

        var voteCounts: [String: Int] = [:]
        for p in players {
            for id in parseVoteIds(p.voteFor) {
                voteCounts[id, default: 0] += 1
            }
        }

        let maxVotes = voteCounts.values.max() ?? 0
        let mostVotedIds = voteCounts.filter { $0.value == maxVotes && $0.value > 0 }.map { $0.key }
        let caughtImposterIds = mostVotedIds.filter { imposterIds.contains($0) }

        let civiliansWon: Bool
        let imposterCaught: Bool
        if imposters.isEmpty {
            civiliansWon = true
            imposterCaught = false
        } else {
            imposterCaught = !caughtImposterIds.isEmpty
            civiliansWon = imposterCaught
        }

        let resultTitle = civiliansWon ? "CIVILIANS WIN!" : "IMPOSTERS WIN!"
        let resultSubtitle: String = {
            if civiliansWon {
                if imposters.isEmpty {
                    return "There were no imposters this round!"
                } else {
                    let names = caughtImposterIds.compactMap { id in players.first(where: { $0.id == id })?.name }.joined(separator: ", ")
                    return "\(names) \(caughtImposterIds.count > 1 ? "were" : "was") caught!"
                }
            } else if mostVotedIds.count > 1 {
                return "A tie in voting allowed to imposters to escape!"
            } else if maxVotes == 0 {
                return "Nobody voted, and imposters got away!"
            } else {
                return "The wrong person was eliminated!"
            }
        }()

        let sortedScores = viewModel.sessionScores.sorted { $0.score > $1.score }
        let skipVotes = players.filter { $0.hasVoted && $0.voteFor == nil }.count

        return ResultsData(
            imposters: imposters,
            imposterIds: imposterIds,
            voteCounts: voteCounts,
            maxVotes: maxVotes,
            mostVotedIds: mostVotedIds,
            caughtImposterIds: caughtImposterIds,
            imposterCaught: imposterCaught,
            civiliansWon: civiliansWon,
            resultTitle: resultTitle,
            resultSubtitle: resultSubtitle,
            sortedScores: sortedScores,
            skipVotes: skipVotes,
            secretWord: game.word ?? "",
            imposterClue: game.imposterClue ?? ""
        )
    }

    var body: some View {
        ZStack {
            ResultsBackdrop(
                animateBackdrop: animateBackdrop,
                highlight: resultAccent.opacity(0.24),
                secondary: secondaryAccent.opacity(0.2)
            )

            if showRedBorder {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(theme.destructive, lineWidth: 8)
                    .ignoresSafeArea()
                    .scaledPadding(.all, 4.0)
                    .opacity(showRedBorder ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5), value: showRedBorder)
                    .neonGlow(color: theme.destructive)
            }

            if let data = resultsData {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ScreenScale.height(20)) {
                        heroSection(data: data)
                        wordRevealSection(data: data)
                        voteResultsSection(data: data)
                        leaderboardSection(data: data)
                        footerSection
                        Spacer(minLength: ScreenScale.height(26))
                    }
                    .scaledPadding(.horizontal, 20.0)
                    .scaledPadding(.top, 24.0)
                    .scaledPadding(.bottom, 24.0)
                }

                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
            }

            homeButtonOverlay
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animateBackdrop = true
            }

            if let data = resultsData {
                if data.civiliansWon {
                    showConfetti = true
                } else {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showRedBorder = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showRedBorder = false
                        }
                    }
                }
            }
        }
    }

    private var resultAccent: Color {
        resultsData?.civiliansWon == true ? theme.success : theme.imposter
    }

    private var secondaryAccent: Color {
        resultsData?.civiliansWon == true ? theme.civilian : theme.warning
    }

    private func heroSection(data: ResultsData) -> some View {
        VStack(spacing: ScreenScale.height(16)) {
            HStack(spacing: 10) {
                resultChip(title: "RESULTS", accent: theme.accent)
                resultChip(title: data.civiliansWon ? "CIVILIAN VICTORY" : "IMPOSTER VICTORY", accent: resultAccent)
            }

            ZStack {
                Circle()
                    .fill(resultAccent.opacity(0.16))
                    .scaledFrame(width: 106, height: 106)
                    .overlay(Circle().stroke(resultAccent.opacity(0.48), lineWidth: 1.2))
                    .neonGlow(color: resultAccent)

                Image(systemName: data.civiliansWon ? "checkmark.seal.fill" : "eye.trianglebadge.exclamationmark")
                    .font(.system(size: ScreenScale.font(46), weight: .bold))
                    .foregroundColor(resultAccent)
            }

            VStack(spacing: 10) {
                Text(data.resultTitle)
                    .font(.system(size: ScreenScale.font(32), weight: .black))
                    .tracking(-1.2)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(data.resultSubtitle)
                    .font(.system(size: ScreenScale.font(14), weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                summaryPill(title: "TOP VOTES", value: "\(data.maxVotes)", accent: theme.accentSecondary)
                summaryPill(title: "SKIPS", value: "\(data.skipVotes)", accent: theme.warning)
                summaryPill(title: "IMPOSTERS", value: "\(data.imposters.count)", accent: theme.imposter)
            }
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.all, 22.0)
        .background(panelBackground(accent: resultAccent))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(panelBorder(accent: resultAccent))
        .premiumShadow()
    }

    private func wordRevealSection(data: ResultsData) -> some View {
        VStack(spacing: ScreenScale.height(20)) {
            sectionTitle("REVEAL")

            VStack(spacing: ScreenScale.height(16)) {
                wordCard(label: "SECRET WORD", value: data.secretWord.uppercased(), accent: theme.civilian)
                wordCard(label: "IMPOSTER CLUE", value: data.imposterClue.uppercased(), accent: theme.imposter, italic: true)
            }
        }
        .scaledPadding(.all, 20.0)
        .background(panelBackground(accent: theme.accentSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(panelBorder(accent: theme.accentSecondary))
        .premiumShadow()
    }

    private func wordCard(label: String, value: String, accent: Color, italic: Bool = false) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.appCaption)
                .foregroundColor(theme.textSecondary.opacity(0.84))
                .tracking(3)

            if italic {
                Text(value)
                    .font(.system(size: ScreenScale.font(22), weight: .black))
                    .foregroundColor(theme.textPrimary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .tracking(-0.8)
                    .neonGlow(color: accent)
            } else {
                Text(value)
                    .font(.system(size: ScreenScale.font(30), weight: .black))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .tracking(-0.8)
                    .neonGlow(color: accent)
            }
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.vertical, 20.0)
        .scaledPadding(.horizontal, 18.0)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surface.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.16), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.36), lineWidth: 1)
        )
    }

    private func voteResultsSection(data: ResultsData) -> some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(14)) {
            sectionTitle("VOTE RESULTS")

            VStack(spacing: ScreenScale.height(12)) {
                ForEach(players) { player in
                    let votes = data.voteCounts[player.id] ?? 0
                    let isMostVoted = data.mostVotedIds.contains(player.id)
                    voteRow(player: player, votes: votes, isMostVoted: isMostVoted)
                }
            }
        }
        .scaledPadding(.all, 20.0)
        .background(panelBackground(accent: theme.warning))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(panelBorder(accent: theme.warning))
        .premiumShadow()
    }

    private func voteRow(player: Player, votes: Int, isMostVoted: Bool) -> some View {
        let accent = player.isImposter ? theme.imposter : theme.civilian

        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .scaledFrame(width: 40, height: 40)
                    .overlay(Circle().stroke(accent.opacity(0.42), lineWidth: 1))
                Text(String(player.name.prefix(1)).uppercased())
                    .font(.system(size: ScreenScale.font(14), weight: .bold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(player.name)
                        .font(.system(size: ScreenScale.font(15), weight: .bold))
                        .foregroundColor(theme.textPrimary)

                    if player.isImposter {
                        Text("IMPOSTER")
                            .font(.system(size: ScreenScale.font(9), weight: .bold))
                            .tracking(1)
                            .foregroundColor(theme.textOnAccent)
                            .scaledPadding(.horizontal, 8.0)
                            .scaledPadding(.vertical, 4.0)
                            .background(Capsule().fill(theme.imposter))
                    }
                }

                let clues = parseClues(player.clue)
                if !clues.isEmpty {
                    Text(clues.joined(separator: " • ").uppercased())
                        .font(.system(size: ScreenScale.font(10), weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.8))
                        .tracking(1.1)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(votes)")
                    .font(.system(size: ScreenScale.font(22), weight: .black))
                    .foregroundColor(isMostVoted ? resultAccent : theme.textPrimary)
                Text("VOTES")
                    .font(.system(size: ScreenScale.font(10), weight: .bold))
                    .foregroundColor(theme.textSecondary)
                    .tracking(1.2)
            }
        }
        .scaledPadding(.all, 18.0)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surface.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [(isMostVoted ? resultAccent : accent).opacity(0.14), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke((isMostVoted ? resultAccent : accent).opacity(isMostVoted ? 0.68 : 0.24), lineWidth: isMostVoted ? 1.4 : 1)
        )
    }

    private func leaderboardSection(data: ResultsData) -> some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(14)) {
            sectionTitle("SESSION LEADERBOARD")

            VStack(spacing: ScreenScale.height(10)) {
                ForEach(Array(data.sortedScores.enumerated()), id: \.element.id) { index, score in
                    leaderboardRow(index: index, score: score)
                }
            }
        }
        .scaledPadding(.all, 20.0)
        .background(panelBackground(accent: theme.accent))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(panelBorder(accent: theme.accent))
        .premiumShadow()
    }

    private func leaderboardRow(index: Int, score: SessionScore) -> some View {
        let playerName = players.first(where: { $0.id == score.playerId })?.name ?? "Unknown"
        let accent: Color = index == 0 ? theme.warning : (index == 1 ? theme.accent : theme.accentSecondary)

        return HStack(spacing: 16) {
            Text("#\(index + 1)")
                .font(.system(size: ScreenScale.font(12), weight: .bold))
                .foregroundColor(accent)
                .scaledFrame(width: 36)

            Text(playerName)
                .font(.system(size: ScreenScale.font(15), weight: .bold))
                .foregroundColor(theme.textPrimary)

            Spacer()

            Text("\(score.score) PTS")
                .font(.system(size: ScreenScale.font(12), weight: .bold))
                .foregroundColor(accent)
                .tracking(0.8)
        }
        .scaledPadding(.all, 18.0)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.surface.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.14), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
    }

    private var footerSection: some View {
        Group {
            if isHost {
                Button {
                    #if canImport(UIKit)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    #endif
                    Task {
                        await viewModel.playAgain()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("PLAY AGAIN")
                            .font(.system(size: ScreenScale.font(15), weight: .bold))
                            .tracking(1)
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: ScreenScale.font(16), weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .scaledPadding(.vertical, 20.0)
                    .foregroundColor(theme.textOnAccent)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accent, theme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .neonGlow(color: theme.accent)
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                WaitingIndicator(message: "Waiting for host to rematch")
                    .frame(maxWidth: .infinity)
                    .scaledPadding(.all, 22.0)
                    .background(panelBackground(accent: theme.accentSecondary))
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(panelBorder(accent: theme.accentSecondary))
            }
        }
    }

    private func resultChip(title: String, accent: Color) -> some View {
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

    private func summaryPill(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: ScreenScale.font(9), weight: .bold))
                .tracking(1.4)
                .foregroundColor(theme.textSecondary)
            Text(value)
                .font(.system(size: ScreenScale.font(15), weight: .black))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.vertical, 12.0)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.surface.opacity(0.84))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(accent.opacity(0.26), lineWidth: 1))
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.appCaption)
            .foregroundColor(theme.textSecondary.opacity(0.84))
            .tracking(3)
    }

    private func panelBackground(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.surface.opacity(0.95), theme.surfaceElevated.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.18), .clear],
                            center: .topTrailing,
                            startRadius: 10,
                            endRadius: 240
                        )
                    )
            )
    }

    private func panelBorder(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [accent.opacity(0.68), theme.border.opacity(0.75), .clear],
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
                        .neonGlow(color: resultAccent)
                }
            }
            .scaledPadding(.horizontal, 20.0)
            .scaledPadding(.top, 20.0)

            Spacer()
        }
    }
}

private struct ResultsBackdrop: View {
    @Environment(\.theme) private var theme

    let animateBackdrop: Bool
    let highlight: Color
    let secondary: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.background, theme.surfaceElevated.opacity(0.95), theme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(highlight)
                .scaledFrame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: animateBackdrop ? 120 : -120, y: -280)

            Circle()
                .fill(secondary)
                .scaledFrame(width: 280, height: 280)
                .blur(radius: 58)
                .offset(x: animateBackdrop ? -120 : 120, y: 260)

            RoundedRectangle(cornerRadius: 0)
                .stroke(theme.border.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [7, 10]))
                .rotationEffect(.degrees(animateBackdrop ? 7 : -7))
                .scaleEffect(1.18)
                .ignoresSafeArea()
        }
    }
}

struct ConfettiView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(
                    color: confettiColors[index % confettiColors.count],
                    delay: Double(index) * 0.08,
                    duration: 3.0 + Double.random(in: 0...2)
                )
            }
        }
    }

    private var confettiColors: [Color] {
        [theme.imposter, theme.warning, theme.success, theme.civilian, theme.accent, theme.accentSecondary]
    }
}

struct ConfettiPiece: View {
    let color: Color
    let delay: Double
    let duration: Double

    @State private var yOffset: CGFloat = -ScreenScale.screenHeight
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .scaledFrame(width: 8, height: 12)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                let randomX = CGFloat.random(in: -220...220)
                let randomRotation = Double.random(in: 0...360)

                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    xOffset = randomX
                    yOffset = ScreenScale.screenHeight + 100
                    rotation = randomRotation
                    opacity = 0
                }
            }
    }
}

struct ResultsData {
    let imposters: [Player]
    let imposterIds: Set<String>
    let voteCounts: [String: Int]
    let maxVotes: Int
    let mostVotedIds: [String]
    let caughtImposterIds: [String]
    let imposterCaught: Bool
    let civiliansWon: Bool
    let resultTitle: String
    let resultSubtitle: String
    let sortedScores: [SessionScore]
    let skipVotes: Int
    let secretWord: String
    let imposterClue: String
}
