import Foundation

// MARK: - Word Generator Service
/// Handles AI-based word generation as a fallback when the local word bank is exhausted.
struct WordGeneratorService {
    static func generateWordPairWithAI(
        difficulty: Difficulty,
        excludeWords: Set<String>
    ) async -> (word: String, imposterClue: String)? {
        do {
            let result = try await SupabaseService.shared.invokeGenerateWord(
                difficulty: difficulty.rawValue,
                excludeWords: Array(excludeWords)
            )
            return result
        } catch {
            print("AI word generation failed: \(error)")
            return nil
        }
    }
}
