import Foundation

// MARK: - Game Code Generation
func generateGameCode() -> String {
    let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    var code = ""
    for _ in 0..<5 {
        let index = chars.index(chars.startIndex, offsetBy: Int.random(in: 0..<chars.count))
        code.append(chars[index])
    }
    return code
}

// MARK: - Shuffle Array
func shuffleArray<T>(_ array: [T]) -> [T] {
    var shuffled = array
    for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
        let j = Int.random(in: 0...i)
        shuffled.swapAt(i, j)
    }
    return shuffled
}

// MARK: - Parse Vote IDs
/// Parses vote_for field which can be a JSON array string or a single ID string.
func parseVoteIds(_ voteFor: String?) -> [String] {
    guard let voteFor = voteFor, !voteFor.isEmpty else { return [] }
    if let data = voteFor.data(using: .utf8),
       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] {
        return parsed
    }
    return [voteFor]
}

// MARK: - Parse Clues
/// Parses clue field which can be a JSON array string or a single clue string.
func parseClues(_ clue: String?) -> [String] {
    guard let clue = clue, !clue.isEmpty else { return [] }
    if let data = clue.data(using: .utf8),
       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] {
        return parsed
    }
    return [clue]
}

// MARK: - Has Clue For Round
func hasClueForRound(_ clue: String?, round: Int) -> Bool {
    return parseClues(clue).count >= round
}

// MARK: - Normalize Imposter Clue
/// Restricts imposter clue to a single word (first token).
func normalizeImposterClueToOneWord(_ clue: String) -> String {
    let trimmed = clue.trimmingCharacters(in: .whitespaces)
    let first = trimmed.split(separator: " ").first ?? ""
    return String(first)
}
