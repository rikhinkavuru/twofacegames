import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ResultsScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showConfetti = false
    @State private var showRedBorder = false

    private var players: [Player] { viewModel.players }
    private var isHost: Bool { viewModel.isHost }

    // MARK: - Computed Properties for Results
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
        
        // Handle win conditions
        let civiliansWon: Bool
        let imposterCaught: Bool
        if imposters.isEmpty {
            // No imposters - civilians automatically win
            civiliansWon = true
            imposterCaught = false
        } else {
            // There are imposters - check if any were caught
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
            Color.appBackground.ignoresSafeArea()
            
            // Red border flash for imposters win
            if showRedBorder {
                Rectangle()
                    .fill(Color.clear)
                    .stroke(Color.red, lineWidth: 8)
                    .ignoresSafeArea()
                    .opacity(showRedBorder ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5), value: showRedBorder)
            }

            if let data = resultsData {
                ScrollView {
                    VStack(spacing: 48) {
                        headerSection
                        revealSection(data: data)
                        wordRevealSection(data: data)
                        voteResultsSection(data: data)
                        leaderboardSection(data: data)
                        footerSection
                        Spacer(minLength: 40)
                    }
                    .scaledPadding(.bottom, 20.0)
                }
                
                // Confetti animation for imposters win
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
            }
            
            homeButtonOverlay
        }
        .onAppear {
            if let data = resultsData {
                if data.civiliansWon {
                    // Civilians won - show confetti
                    showConfetti = true
                } else {
                    // Imposters won - show red border
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showRedBorder = true
                    }
                    
                    // Hide red border after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showRedBorder = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sub-views
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("RESULTS")
                .font(.appCaption)
                .foregroundColor(.appMutedForeground.opacity(0.6))
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.top, 20.0)
    }

    private func revealSection(data: ResultsData) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(data.civiliansWon ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .scaledFrame(width: 80, height: 80)
                
                Image(systemName: data.civiliansWon ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: ScreenScale.font(40), weight: .bold))
                    .foregroundColor(data.civiliansWon ? .green : .red)
            }
            .scaledPadding(.top, 20.0)

            VStack(spacing: 12) {
                Text(data.resultTitle)
                    .font(.system(size: ScreenScale.font(32), weight: .bold))
                    .tracking(-1)
                    .foregroundColor(data.civiliansWon ? .green : .red)

                Text(data.resultSubtitle)
                    .font(.system(size: ScreenScale.font(14), weight: .medium))
                    .foregroundColor(.black.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .scaledPadding(.horizontal, 32.0)
            }
        }
    }

    private func wordRevealSection(data: ResultsData) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("SECRET WORD")
                    .font(.system(size: ScreenScale.font(11), weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(4)
                
                Text(data.secretWord.uppercased())
                    .font(.system(size: ScreenScale.font(36), weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .scaledFrame(width: 60, height: 2)
                .clipShape(Capsule())
            
            VStack(spacing: 8) {
                Text("IMPOSTER CLUE")
                    .font(.system(size: ScreenScale.font(11), weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(4)
                
                Text(data.imposterClue.uppercased())
                    .font(.system(size: ScreenScale.font(22), weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .italic()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .scaledPadding(.vertical, 40.0)
        .scaledPadding(.horizontal, 32.0)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .scaledPadding(.horizontal, 24.0)
    }

    private func voteResultsSection(data: ResultsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VOTE RESULTS")
                .font(.system(size: ScreenScale.font(11), weight: .bold))
                .foregroundColor(.black.opacity(0.4))
                .tracking(3)

            VStack(spacing: 12) {
                ForEach(players) { player in
                    let votes = data.voteCounts[player.id] ?? 0
                    let isMostVoted = data.mostVotedIds.contains(player.id)
                    
                    voteRow(player: player, votes: votes, isMostVoted: isMostVoted)
                }
            }
        }
        .scaledPadding(.horizontal, 32.0)
    }
    
    private func voteRow(player: Player, votes: Int, isMostVoted: Bool) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(player.isImposter ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                .scaledFrame(width: 32, height: 32)
                .overlay(
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: ScreenScale.font(12), weight: .bold))
                        .foregroundColor(player.isImposter ? .red : .blue)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(player.name)
                        .font(.system(size: ScreenScale.font(14), weight: .semibold))
                        .foregroundColor(.black)

                    if player.isImposter {
                        Text("IMPOSTER")
                            .font(.system(size: ScreenScale.font(9), weight: .bold))
                            .foregroundColor(.white)
                            .scaledPadding(.horizontal, 8.0)
                            .scaledPadding(.vertical, 4.0)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }

                let clues = parseClues(player.clue)
                if !clues.isEmpty {
                    Text(clues.joined(separator: " \u{2022} ").uppercased())
                        .font(.system(size: ScreenScale.font(10), weight: .bold))
                        .foregroundColor(.black.opacity(0.3))
                        .tracking(1)
                }
            }

            Spacer()

            Text("\(votes) VOTES")
                .font(.system(size: ScreenScale.font(12), weight: .bold))
                .foregroundColor(isMostVoted ? .black : .black.opacity(0.3))
        }
        .scaledPadding(.all, 16.0)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .premiumShadow()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isMostVoted ? Color.black.opacity(0.1) : Color.clear, lineWidth: 1)
        )
    }

    private func leaderboardSection(data: ResultsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SESSION LEADERBOARD")
                .font(.system(size: ScreenScale.font(11), weight: .bold))
                .foregroundColor(.black.opacity(0.4))
                .tracking(3)

            VStack(spacing: 1) {
                ForEach(Array(data.sortedScores.enumerated()), id: \.element.id) { index, score in
                    leaderboardRow(index: index, score: score)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .premiumShadow()
        }
        .scaledPadding(.horizontal, 32.0)
    }
    
    private func leaderboardRow(index: Int, score: SessionScore) -> some View {
        let playerName = players.first(where: { $0.id == score.playerId })?.name ?? "Unknown"
        return HStack(spacing: 16) {
            Text("\(index + 1)")
                .font(.system(size: ScreenScale.font(12), weight: .bold))
                .foregroundColor(.black.opacity(0.3))
                .scaledFrame(width: 20)

            Text(playerName)
                .font(.system(size: ScreenScale.font(14), weight: .semibold))
                .foregroundColor(.black)

            Spacer()

            Text("\(score.score) PTS")
                .font(.system(size: ScreenScale.font(12), weight: .bold))
                .foregroundColor(.appSoftIndigo)
        }
        .scaledPadding(.all, 20.0)
        .background(Color.white)
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
                            .font(.system(size: ScreenScale.font(14), weight: .bold))
                            .tracking(1)
                        
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: ScreenScale.font(16), weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .scaledPadding(.vertical, 20.0)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                }
                .scaledPadding(.horizontal, 32.0)
            } else {
                WaitingIndicator(message: "Waiting for host to rematch")
                    .scaledPadding(.horizontal, 32.0)
            }
        }
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
                        .font(.system(size: ScreenScale.font(14), weight: .semibold))
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

// MARK: - Confetti Animation
struct ConfettiView: View {
    @State private var animate = false
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(
                    color: colors.randomElement() ?? .red,
                    delay: Double(index) * 0.1,
                    duration: 3.0 + Double.random(in: 0...2)
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    let delay: Double
    let duration: Double
    @State private var yOffset: CGFloat = -UIScreen.main.bounds.height
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Rectangle()
            .fill(color)
            .scaledFrame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                let randomX = CGFloat.random(in: -200...200)
                let randomRotation = Double.random(in: 0...360)
                
                withAnimation(
                    .easeOut(duration: duration)
                    .delay(delay)
                ) {
                    xOffset = randomX
                    yOffset = UIScreen.main.bounds.height + 100
                    rotation = randomRotation
                    opacity = 0
                }
            }
    }
}

// MARK: - Helper Models
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
