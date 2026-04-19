import Foundation

// MARK: - Clue Round State
struct ClueRoundState {
    let sortedPlayers: [Player]
    let playerCount: Int
    let clueRounds: Int
    let currentTurnIndex: Int
    let currentRound: Int
    let turnInRound: Int
    let totalTurns: Int
    let activePlayer: Player?
}

// MARK: - Next Clue Action
enum NextClueAction {
    case advanceTurn(nextTurnIndex: Int)
    case nextRound(nextTurnIndex: Int)
    case startVoting(nextTurnIndex: Int)

    var nextTurnIndex: Int {
        switch self {
        case .advanceTurn(let i), .nextRound(let i), .startVoting(let i):
            return i
        }
    }
}

// MARK: - Get Clue Round State
func getClueRoundState(players: [Player], clueRounds: Int?, currentTurnIndex: Int?) -> ClueRoundState {
    let sortedPlayers = players.sorted { ($0.turnOrder ?? 0) < ($1.turnOrder ?? 0) }
    let playerCount = sortedPlayers.count
    let normalizedClueRounds = max(1, clueRounds ?? 1)
    let normalizedTurnIndex = max(0, currentTurnIndex ?? 0)
    let turnInRound = playerCount > 0 ? normalizedTurnIndex % playerCount : 0
    let currentRound = playerCount > 0 ? (normalizedTurnIndex / playerCount) + 1 : 1

    return ClueRoundState(
        sortedPlayers: sortedPlayers,
        playerCount: playerCount,
        clueRounds: normalizedClueRounds,
        currentTurnIndex: normalizedTurnIndex,
        currentRound: currentRound,
        turnInRound: turnInRound,
        totalTurns: normalizedClueRounds * playerCount,
        activePlayer: playerCount > 0 ? sortedPlayers[turnInRound] : nil
    )
}

// MARK: - Get Next Clue Action
func getNextClueAction(state: ClueRoundState) -> NextClueAction {
    let nextTurnIndex = state.currentTurnIndex + 1

    if state.playerCount == 0 || nextTurnIndex >= state.totalTurns {
        return .startVoting(nextTurnIndex: nextTurnIndex)
    }

    if nextTurnIndex % state.playerCount == 0 {
        return .nextRound(nextTurnIndex: nextTurnIndex)
    }

    return .advanceTurn(nextTurnIndex: nextTurnIndex)
}
