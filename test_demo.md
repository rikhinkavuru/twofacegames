# Demo Mode Implementation Test Plan

## Test Steps:
1. Launch app
2. Click "JOIN GAME"
3. Enter player name (e.g., "Reviewer")
4. Enter game code: "DEMO"
5. Click "JOIN GAME"

## Expected Behavior:
1. **Lobby Phase**:
   - User joins as host
   - Two bots (Test1, Test2) are automatically added
   - Reviewer can see lobby and choose game settings
   - Reviewer can manually start game when ready

2. **Gameplay Phase**:
   - Secret word: "developer" (hardcoded regardless of settings)
   - Imposter clue: "testing" (hardcoded regardless of settings)
   - Test1 is always the imposter for consistency
   - Bots give realistic clues automatically with proper delays
   - Both Test1 and Test2 participate in clue giving
   - Bots vote automatically with intelligent logic

3. **Complete Flow**:
   - Role reveal → Clue giving → Voting → Results
   - No errors or softlocks
   - Full game functionality demonstrated
   - Works with any game settings chosen by reviewer

## Fixes Implemented:
- **Multiple Demo Sessions**: DEMO code can be reused - existing demo games are cleaned up automatically
- **Bot Participation**: Both bots now properly participate in clue giving and voting
- **Lobby Control**: Reviewer can see lobby and choose settings before starting
- **Settings Compatibility**: Demo works regardless of game settings chosen
- **Consistent Experience**: Test1 is always imposter, word/clue are hardcoded

## Implementation Details:
- DEMO code detection and cleanup in `joinGame()`
- `createDemoGame()` creates game with bots but doesn't auto-start
- `startGame()` uses hardcoded word/clue for DEMO mode regardless of settings
- Improved bot simulation with real-time state checking
- Automatic phase progression with realistic delays
