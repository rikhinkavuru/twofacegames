import Foundation

// MARK: - Game Phase
enum GamePhase: String, Codable, CaseIterable {
    case lobby
    case roleReveal = "role_reveal"
    case clueGiving = "clue_giving"
    case voting
    case results
}

// MARK: - Difficulty
enum Difficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Close clue"
        case .medium: return "Related clue"
        case .hard: return "Loose clue"
        }
    }

    var iconName: String {
        switch self {
        case .easy: return "bolt.fill"
        case .medium: return "flame.fill"
        case .hard: return "brain.head.profile"
        }
    }
}

// MARK: - Game
struct Game: Identifiable, Codable, Equatable {
    let id: String
    var code: String
    var hostPlayerId: String?
    var phase: GamePhase
    var word: String?
    var imposterClue: String?
    var currentTurnIndex: Int?
    var difficulty: String
    var imposterCount: Int
    var imposterMin: Int
    var imposterMax: Int
    var imposterRandom: Bool
    var clueRounds: Int
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case hostPlayerId = "host_player_id"
        case phase
        case word
        case imposterClue = "imposter_clue"
        case currentTurnIndex = "current_turn_index"
        case difficulty
        case imposterCount = "imposter_count"
        case imposterMin = "imposter_min"
        case imposterMax = "imposter_max"
        case imposterRandom = "imposter_random"
        case clueRounds = "clue_rounds"
        case createdAt = "created_at"
    }

    var difficultyEnum: Difficulty {
        Difficulty(rawValue: difficulty) ?? .medium
    }

    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id &&
        lhs.phase == rhs.phase &&
        lhs.word == rhs.word &&
        lhs.imposterClue == rhs.imposterClue &&
        lhs.currentTurnIndex == rhs.currentTurnIndex &&
        lhs.difficulty == rhs.difficulty &&
        lhs.imposterMin == rhs.imposterMin &&
        lhs.imposterMax == rhs.imposterMax &&
        lhs.imposterRandom == rhs.imposterRandom &&
        lhs.clueRounds == rhs.clueRounds &&
        lhs.hostPlayerId == rhs.hostPlayerId
    }
}

// MARK: - Player
struct Player: Identifiable, Codable, Equatable {
    let id: String
    var gameId: String
    var name: String
    var isHost: Bool
    var isImposter: Bool
    var clue: String?
    var voteFor: String?
    var turnOrder: Int?
    var hasVoted: Bool
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case name
        case isHost = "is_host"
        case isImposter = "is_imposter"
        case clue
        case voteFor = "vote_for"
        case turnOrder = "turn_order"
        case hasVoted = "has_voted"
        case createdAt = "created_at"
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.isHost == rhs.isHost &&
        lhs.isImposter == rhs.isImposter &&
        lhs.clue == rhs.clue &&
        lhs.voteFor == rhs.voteFor &&
        lhs.turnOrder == rhs.turnOrder &&
        lhs.hasVoted == rhs.hasVoted
    }
}

// MARK: - Session Score (client-side only)
struct SessionScore: Identifiable, Equatable {
    let id: String
    let playerId: String
    var score: Int
    var roundsWon: Int
    var correctVotes: Int
}
