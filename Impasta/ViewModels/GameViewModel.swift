import Foundation
import Supabase
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var game: Game?
    @Published var players: [Player] = []
    @Published var sessionScores: [SessionScore] = []
    @Published var currentPlayerId: String?
    @Published var loading = false
    @Published var error: String?

    // MARK: - Derived
    var currentPlayer: Player? {
        players.first { $0.id == currentPlayerId }
    }
    var isHost: Bool {
        currentPlayer?.isHost ?? false
    }

    // MARK: - Private
    private var usedWords: Set<String> = []
    private var scoredRoundKey: String?
    private var realtimeChannel: RealtimeChannelV2?
    private let supabase = SupabaseService.shared

    // MARK: - Create Game
    func createGame(hostName: String) async {
        loading = true
        error = nil
        usedWords = []
        sessionScores = []
        scoredRoundKey = nil

        do {
            let code = generateGameCode()
            let gameData = try await supabase.createGame(code: code)
            let playerData = try await supabase.createPlayer(gameId: gameData.id, name: hostName, isHost: true)
            try await supabase.updateGame(id: gameData.id, values: ["host_player_id": .string(playerData.id)])

            var updatedGame = gameData
            updatedGame.hostPlayerId = playerData.id
            self.game = updatedGame
            self.currentPlayerId = playerData.id
            self.players = [playerData]

            subscribeToRealtime()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    // MARK: - Join Game
    func joinGame(code: String, playerName: String) async {
        loading = true
        error = nil
        sessionScores = []
        scoredRoundKey = nil
        
        let uppercasedCode = code.uppercased()

        // Check for DEMO mode
        if uppercasedCode == "DEMO" {
            do {
                // Try to fetch existing DEMO game first
                let existingGame = try await supabase.fetchGame(byCode: "DEMO")
                // If game exists and is not in lobby, clean it up first
                if existingGame.phase != .lobby {
                    // Clean up existing demo game by deleting players
                    let existingPlayers = try await supabase.fetchPlayers(gameId: existingGame.id)
                    for player in existingPlayers {
                        _ = try? await supabase.client
                            .from("players")
                            .delete()
                            .eq("id", value: player.id)
                            .execute()
                    }
                    // Delete the game
                    _ = try? await supabase.client
                        .from("games")
                        .delete()
                        .eq("code", value: "DEMO")
                        .execute()
                }
            } catch {
                // No existing game or other error, proceed with creating new one
            }
            
            await createDemoGame(hostName: playerName)
            loading = false
            return
        }

        do {
            let gameData = try await supabase.fetchGame(byCode: uppercasedCode)
            guard gameData.phase == .lobby else {
                self.error = "Game already in progress."
                loading = false
                return
            }
            let playerData = try await supabase.createPlayer(gameId: gameData.id, name: playerName)
            self.game = gameData
            self.currentPlayerId = playerData.id
            await fetchPlayers()
            subscribeToRealtime()
        } catch {
            self.error = "Game not found. Check the code and try again."
        }
        loading = false
    }

    // MARK: - Create Demo Game
    private func createDemoGame(hostName: String) async {
        do {
            // Create demo game with DEMO code
            let gameData = try await supabase.createGame(code: "DEMO")
            let hostPlayerData = try await supabase.createPlayer(gameId: gameData.id, name: hostName, isHost: true)
            
            // Create bot players
            let bot1Data = try await supabase.createPlayer(gameId: gameData.id, name: "Test1")
            let bot2Data = try await supabase.createPlayer(gameId: gameData.id, name: "Test2")
            
            // Update game with host
            try await supabase.updateGame(id: gameData.id, values: ["host_player_id": .string(hostPlayerData.id)])
            
            var updatedGame = gameData
            updatedGame.hostPlayerId = hostPlayerData.id
            self.game = updatedGame
            self.currentPlayerId = hostPlayerData.id
            self.players = [hostPlayerData, bot1Data, bot2Data]
            
            // Don't auto-start - let reviewer choose settings and start manually
            // subscribeToRealtime() will be called after this function returns
            
            subscribeToRealtime()
        } catch {
            self.error = "Failed to create demo game: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Update Settings
    func updateSettings(_ settings: GameSettings) async {
        guard let game = game, isHost else { return }
        try? await supabase.updateGame(id: game.id, values: [
            "difficulty": .string(settings.difficulty.rawValue),
            "imposter_random": .bool(settings.imposterRandom),
            "imposter_min": .integer(settings.imposterMin),
            "imposter_max": .integer(settings.imposterMax),
            "clue_rounds": .integer(settings.clueRounds),
        ])
    }

    // MARK: - Start Game
    func startGame(customWord: String? = nil, customClue: String? = nil) async {
        guard let game = game, isHost else { return }

        var wordPair: (word: String, imposterClue: String)
        
        // For DEMO mode, always use hardcoded word and clue regardless of settings
        if game.code == "DEMO" {
            wordPair = (word: "developer", imposterClue: "testing")
        } else {
            let difficulty = game.difficultyEnum
            
            if let cw = customWord, let cc = customClue, !cw.isEmpty, !cc.isEmpty {
                wordPair = (word: cw, imposterClue: normalizeImposterClueToOneWord(cc))
            } else {
                wordPair = getRandomWordPair(difficulty: difficulty)

                if usedWords.contains(wordPair.word.lowercased()) {
                    if let aiPair = await WordGeneratorService.generateWordPairWithAI(
                        difficulty: difficulty, excludeWords: usedWords
                    ) {
                        wordPair = aiPair
                    }
                }
            }
        }

        let currentPlayers = players
        let playerIds = currentPlayers.map { $0.id }
        let imposterPickOrder = shuffleArray(playerIds)
        
        // For DEMO mode, ensure host goes first, then bots
        let clueOrder: [String]
        if game.code == "DEMO" {
            let hostId = currentPlayers.first { $0.isHost }?.id
            let botIds = currentPlayers.filter { !$0.isHost }.map { $0.id }
            if let host = hostId {
                clueOrder = [host] + botIds
            } else {
                clueOrder = shuffleArray(playerIds)
            }
        } else {
            clueOrder = shuffleArray(playerIds)
        }

        let n = currentPlayers.count
        let numImposters: Int
        if game.imposterRandom {
            let minI = max(0, min(game.imposterMin, n))
            let maxI = max(minI, min(game.imposterMax, n))
            numImposters = Int.random(in: minI...maxI)
        } else {
            numImposters = min(game.imposterMin, n)
        }

        let imposterIds: Set<String>
        // For DEMO mode, ensure Test1 is always the imposter for consistency
        if game.code == "DEMO" {
            let test1Bot = currentPlayers.first { $0.name == "Test1" }
            imposterIds = test1Bot != nil ? Set([test1Bot!.id]) : Set(imposterPickOrder.prefix(numImposters))
        } else {
            imposterIds = Set(imposterPickOrder.prefix(numImposters))
        }

        for i in 0..<clueOrder.count {
            let playerId = clueOrder[i]
            try? await supabase.updatePlayer(id: playerId, values: [
                "turn_order": .integer(i),
                "is_imposter": .bool(imposterIds.contains(playerId)),
                "clue": .null,
                "vote_for": .null,
                "has_voted": .bool(false),
            ])
        }

        try? await supabase.updateGame(id: game.id, values: [
            "phase": .string("role_reveal"),
            "word": .string(wordPair.word),
            "imposter_clue": .string(wordPair.imposterClue),
            "current_turn_index": .integer(0),
        ])
    }

    // MARK: - Proceed to Clues
    func proceedToClues() async {
        guard let game = game, isHost else { return }
        try? await supabase.updateGame(id: game.id, values: [
            "phase": .string("clue_giving"),
        ])
    }

    // MARK: - Submit Clue
    func submitClue(_ clue: String) async {
        guard let game = game, let currentPlayerId = currentPlayerId else { return }

        // Fetch fresh state
        let freshPlayers = (try? await supabase.fetchPlayers(gameId: game.id)) ?? players
        let freshGame = (try? await supabase.fetchGame(byCode: game.code)) ?? game

        let clueRoundState = getClueRoundState(
            players: freshPlayers,
            clueRounds: freshGame.clueRounds,
            currentTurnIndex: freshGame.currentTurnIndex
        )

        guard clueRoundState.activePlayer?.id == currentPlayerId else { return }
        guard !hasClueForRound(clueRoundState.activePlayer?.clue, round: clueRoundState.currentRound) else { return }

        // Append clue to JSON array
        let existingClues = parseClues(clueRoundState.activePlayer?.clue)
        let updatedClues = existingClues + [clue]
        let clueJSON: String
        if let data = try? JSONSerialization.data(withJSONObject: updatedClues),
           let str = String(data: data, encoding: .utf8) {
            clueJSON = str
        } else {
            clueJSON = "[\"\(clue)\"]"
        }

        try? await supabase.updatePlayer(id: currentPlayerId, values: [
            "clue": .string(clueJSON),
        ])

        let nextAction = getNextClueAction(state: clueRoundState)

        switch nextAction {
        case .startVoting(_):
            try? await supabase.updateGame(id: game.id, values: [
                "phase": .string("voting"),
            ])
        case .nextRound(let nextIdx):
            try? await supabase.updateGame(id: game.id, values: [
                "current_turn_index": .integer(nextIdx),
            ])
        case .advanceTurn(let nextIdx):
            try? await supabase.updateGame(id: game.id, values: [
                "current_turn_index": .integer(nextIdx),
            ])
        }
    }

    // MARK: - Submit Vote
    func submitVote(votedPlayerIds: [String]) async {
        guard let game = game, let currentPlayerId = currentPlayerId else { return }

        let voteValue: AnyJSON
        if votedPlayerIds.isEmpty {
            voteValue = .null
        } else {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(votedPlayerIds),
               let str = String(data: data, encoding: .utf8) {
                voteValue = .string(str)
            } else {
                voteValue = .null
            }
        }

        try? await supabase.updatePlayer(id: currentPlayerId, values: [
            "vote_for": voteValue,
            "has_voted": .bool(true),
        ])

        // Check if all voted
        let freshPlayers = (try? await supabase.fetchPlayers(gameId: game.id)) ?? players
        let allVoted = freshPlayers.allSatisfy { $0.hasVoted }
        if allVoted {
            try? await supabase.updateGame(id: game.id, values: [
                "phase": .string("results"),
            ])
        }
    }

    // MARK: - Play Again
    func playAgain() async {
        guard let game = game, isHost else { return }

        for p in players {
            try? await supabase.updatePlayer(id: p.id, values: [
                "is_imposter": .bool(false),
                "clue": .null,
                "vote_for": .null,
                "turn_order": .null,
                "has_voted": .bool(false),
            ])
        }

        try? await supabase.updateGame(id: game.id, values: [
            "phase": .string("lobby"),
            "word": .null,
            "imposter_clue": .null,
            "current_turn_index": .integer(0),
        ])
    }

    // MARK: - Refresh State
    func refreshState() async {
        guard let game = game else { return }
        
        do {
            // Re-fetch game and players to ensure synchronization
            let freshGame = try await supabase.fetchGameById(game.id)
            let freshPlayers = try await supabase.fetchPlayers(gameId: game.id)
            
            self.game = freshGame
            self.players = freshPlayers
            
            // Re-subscribe only if we don't have an active channel
            if realtimeChannel == nil {
                subscribeToRealtime()
            }
        } catch {
        }
    }

    // MARK: - Fetch Players
    func fetchPlayers() async {
        guard let game = game else { return }
        if let data = try? await supabase.fetchPlayers(gameId: game.id) {
            self.players = data
        }
    }

    // MARK: - Realtime Subscription
    private func subscribeToRealtime() {
        guard let game = game else { return }

        // Unsubscribe previous if it exists
        if let channel = realtimeChannel {
            supabase.unsubscribe(channel: channel)
            realtimeChannel = nil
        }

        realtimeChannel = supabase.subscribeToGame(
            gameId: game.id,
            onGameUpdate: { [weak self] updatedGame in
                guard let self = self else { return }
                
                // Only update if phase or critical data changed to avoid UI flickers
                if self.game?.phase != updatedGame.phase || 
                   self.game?.currentTurnIndex != updatedGame.currentTurnIndex ||
                   self.game?.word != updatedGame.word {
                    
                    let oldPhase = self.game?.phase
                    self.game = updatedGame

                    // Track used words
                    if let word = updatedGame.word {
                        self.usedWords.insert(word.lowercased())
                    }

                    // Initialize scores on role reveal
                    if updatedGame.phase == .roleReveal {
                        self.initializeScores()
                    }

                    // Handle bot behavior for demo mode
                    if updatedGame.code == "DEMO" {
                        Task {
                            await self.handleBotBehavior(game: updatedGame, previousPhase: oldPhase)
                        }
                    }

                    // Compute scores on results
                    if updatedGame.phase == .results && oldPhase != .results {
                        self.computeScores()
                    }
                }
            },
            onPlayersUpdate: { [weak self] in
                Task { [weak self] in
                    await self?.fetchPlayers()
                }
            }
        )
    }
    
    // MARK: - Bot Behavior System
    private func handleBotBehavior(game: Game, previousPhase: GamePhase?) async {
        // Only handle bot behavior in demo mode
        guard game.code == "DEMO" else { return }
        
        switch game.phase {
        case .clueGiving:
            // Process bot turns immediately
            await simulateBotClueGiving(game: game)
            
        case .voting:
            if previousPhase == .clueGiving {
                // Process bot votes immediately when entering voting
                await simulateBotVoting(game: game)
            }
            
        default:
            break
        }
    }
    
    private func simulateBotClueGiving(game: Game) async {
        guard game.code == "DEMO" else { return }
        
        // Get fresh game state once
        guard let freshGame = try? await supabase.fetchGame(byCode: game.code) else { return }
        guard let freshPlayers = try? await supabase.fetchPlayers(gameId: freshGame.id) else { return }
        
        let clueRoundState = getClueRoundState(
            players: freshPlayers,
            clueRounds: freshGame.clueRounds,
            currentTurnIndex: freshGame.currentTurnIndex
        )
        
        // Check if it's a bot's turn and bot hasn't given clue for this round
        if let activePlayer = clueRoundState.activePlayer,
           !activePlayer.isHost && activePlayer.name.hasPrefix("Test"),
           !hasClueForRound(activePlayer.clue, round: clueRoundState.currentRound) {
            
            // Give clue immediately without delay
            let clue: String
            if activePlayer.isImposter {
                clue = generateBotImposterClue()
            } else {
                clue = generateBotCivilianClue()
            }
            
            await submitBotClue(botId: activePlayer.id, clue: clue)
        }
    }
    
    private func simulateBotVoting(game: Game) async {
        guard game.code == "DEMO" else { return }
        
        // Get fresh game state once
        guard let freshGame = try? await supabase.fetchGame(byCode: game.code) else { return }
        guard let freshPlayers = try? await supabase.fetchPlayers(gameId: freshGame.id) else { return }
        
        let bots = freshPlayers.filter { !$0.isHost && $0.name.hasPrefix("Test") }
        
        // Make all bots vote immediately
        for bot in bots {
            if !bot.hasVoted {
                let voteTargets = generateBotVoteTargets(bot: bot)
                await submitBotVote(botId: bot.id, voteTargets: voteTargets)
            }
        }
    }
    
    private func generateBotCivilianClue() -> String {
        // Generate clues that point to "developer" without being too obvious
        let civilianClues = [
            "writes code",
            "programmer",
            "software maker",
            "coder",
            "tech worker",
            "builds apps",
            "computer expert"
        ]
        return civilianClues.randomElement() ?? "writes code"
    }
    
    private func generateBotImposterClue() -> String {
        // Generate misleading clues based on "testing" that could point elsewhere
        let imposterClues = [
            "checking",
            "examining",
            "inspecting",
            "reviewing",
            "analyzing",
            "quality control",
            "verification"
        ]
        return imposterClues.randomElement() ?? "checking"
    }
    
    private func generateBotVoteTargets(bot: Player) -> [String] {
        let otherPlayers = players.filter { $0.id != bot.id }
        
        if bot.isImposter {
            // Imposter bot tries to vote for civilians or avoid voting for fellow imposters
            let civilians = otherPlayers.filter { !$0.isImposter }
            if !civilians.isEmpty {
                return [civilians.randomElement()!.id]
            }
            return []
        } else {
            // Civilian bot tries to vote for who they think is the imposter
            // Simple logic: vote randomly with some bias
            let weights = otherPlayers.map { player in
                player.isImposter ? 0.7 : 0.3 // Higher weight for actual imposters
            }
            
            let randomValue = Double.random(in: 0...1)
            var cumulativeWeight = 0.0
            
            for (index, weight) in weights.enumerated().reversed() {
                cumulativeWeight += weight
                if randomValue <= cumulativeWeight {
                    return [otherPlayers[index].id]
                }
            }
            
            return [otherPlayers.randomElement()!.id]
        }
    }
    
    private func submitBotClue(botId: String, clue: String) async {
        do {
            let existingClues = parseClues(players.first(where: { $0.id == botId })?.clue)
            let updatedClues = existingClues + [clue]
            let clueJSON: String
            if let data = try? JSONSerialization.data(withJSONObject: updatedClues),
               let str = String(data: data, encoding: .utf8) {
                clueJSON = str
            } else {
                clueJSON = "[\"\(clue)\"]"
            }
            
            try await supabase.updatePlayer(id: botId, values: [
                "clue": .string(clueJSON),
            ])
            
            // Check if we should advance to next phase
            if let game = game {
                let freshPlayers = (try? await supabase.fetchPlayers(gameId: game.id)) ?? players
                let freshGame = (try? await supabase.fetchGame(byCode: game.code)) ?? game
                
                let clueRoundState = getClueRoundState(
                    players: freshPlayers,
                    clueRounds: freshGame.clueRounds,
                    currentTurnIndex: freshGame.currentTurnIndex
                )
                
                let nextAction = getNextClueAction(state: clueRoundState)
                
                switch nextAction {
                case .startVoting(_):
                    try await supabase.updateGame(id: game.id, values: [
                        "phase": .string("voting"),
                    ])
                case .nextRound(let nextIdx):
                    try await supabase.updateGame(id: game.id, values: [
                        "current_turn_index": .integer(nextIdx),
                    ])
                case .advanceTurn(let nextIdx):
                    try await supabase.updateGame(id: game.id, values: [
                        "current_turn_index": .integer(nextIdx),
                    ])
                }
            }
        } catch {
            // Handle error silently in demo mode
        }
    }
    
    private func submitBotVote(botId: String, voteTargets: [String]) async {
        do {
            let voteValue: AnyJSON
            if voteTargets.isEmpty {
                voteValue = .null
            } else {
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(voteTargets),
                   let str = String(data: data, encoding: .utf8) {
                    voteValue = .string(str)
                } else {
                    voteValue = .null
                }
            }
            
            try await supabase.updatePlayer(id: botId, values: [
                "vote_for": voteValue,
                "has_voted": .bool(true),
            ])
            
            // Check if all players have voted
            if let game = game {
                let freshPlayers = (try? await supabase.fetchPlayers(gameId: game.id)) ?? players
                let allVoted = freshPlayers.allSatisfy { $0.hasVoted }
                if allVoted {
                    try await supabase.updateGame(id: game.id, values: [
                        "phase": .string("results"),
                    ])
                }
            }
        } catch {
            // Handle error silently in demo mode
        }
    }

    // MARK: - Score Management
    private func initializeScores() {
        let existingIds = Set(sessionScores.map { $0.playerId })
        let newEntries: [SessionScore] = players
            .filter { !existingIds.contains($0.id) }
            .map { SessionScore(id: $0.id, playerId: $0.id, score: 0, roundsWon: 0, correctVotes: 0) }
        if !newEntries.isEmpty {
            sessionScores.append(contentsOf: newEntries)
        }
    }

    private func computeScores() {
        guard let game = game else { return }
        let roundKey = "\(game.id)-\(game.word ?? "")"
        guard scoredRoundKey != roundKey else { return }
        scoredRoundKey = roundKey

        let latestPlayers = players

        // 1. Count votes for each player
        var voteCounts: [String: Int] = [:]
        for p in latestPlayers {
            for id in parseVoteIds(p.voteFor) {
                voteCounts[id, default: 0] += 1
            }
        }

        // 2. Determine who was caught (most voted)
        let maxVotes = voteCounts.values.max() ?? 0
        let mostVotedIds = voteCounts.filter { $0.value == maxVotes && $0.value > 0 }.map { $0.key }
        
        // 3. Check if any imposter was caught
        let caughtImposterIds = mostVotedIds.filter { id in
            latestPlayers.first(where: { $0.id == id })?.isImposter == true
        }
        
        let imposterCaught = !caughtImposterIds.isEmpty
        let civiliansWon = imposterCaught
        let impostersWon = !imposterCaught

        // 4. Update session scores
        sessionScores = sessionScores.map { score in
            guard let player = latestPlayers.first(where: { $0.id == score.playerId }) else { return score }

            var pointsToAdd = 0
            var roundsWonIncrement = 0
            var correctVotesIncrement = 0

            if player.isImposter {
                // Imposters win if they weren't caught
                if impostersWon {
                    pointsToAdd += 10
                    roundsWonIncrement = 1
                }
            } else {
                // Civilians win if at least one imposter was caught
                if civiliansWon {
                    pointsToAdd += 5
                    roundsWonIncrement = 1
                }
                
                // Bonus for voting for an imposter
                if let voteFor = player.voteFor {
                    let votedIds = parseVoteIds(voteFor)
                    let correctVotes = votedIds.filter { id in
                        latestPlayers.first(where: { $0.id == id })?.isImposter == true
                    }
                    if !correctVotes.isEmpty {
                        pointsToAdd += 3 * correctVotes.count
                        correctVotesIncrement = correctVotes.count
                    }
                }
            }

            return SessionScore(
                id: score.id,
                playerId: score.playerId,
                score: score.score + pointsToAdd,
                roundsWon: score.roundsWon + roundsWonIncrement,
                correctVotes: score.correctVotes + correctVotesIncrement
            )
        }
    }

    // MARK: - Exit Game
    func exitGame() {
        // 1. Immediate UI update to prevent double-taps
        _ = game?.id
        
        // 2. Reset all local state synchronously
        self.game = nil
        self.players = []
        self.currentPlayerId = nil
        self.sessionScores = []
        self.usedWords = []
        self.scoredRoundKey = nil
        self.loading = false
        self.error = nil
        
        // 3. Cleanup background tasks and subscriptions
        cleanup()
    }

    // MARK: - Cleanup
    func cleanup() {
        if let channel = realtimeChannel {
            supabase.unsubscribe(channel: channel)
        }
    }
}
