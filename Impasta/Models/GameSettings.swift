import Foundation

struct GameSettings {
    var difficulty: Difficulty
    var imposterRandom: Bool
    var imposterMin: Int
    var imposterMax: Int
    var clueRounds: Int

    init(
        difficulty: Difficulty = .medium,
        imposterRandom: Bool = false,
        imposterMin: Int = 1,
        imposterMax: Int = 1,
        clueRounds: Int = 1
    ) {
        self.difficulty = difficulty
        self.imposterRandom = imposterRandom
        self.imposterMin = imposterMin
        self.imposterMax = imposterMax
        self.clueRounds = clueRounds
    }
}
