# Impasta SwiftUI Architecture

## Project Structure
```
Impasta/
├── Impasta.xcodeproj/
├── Impasta/
│   ├── App/
│   │   ├── ImpasterApp.swift          (entry point)
│   │   └── ContentView.swift          (root view with phase routing)
│   ├── Models/
│   │   ├── GameModels.swift           (Game, Player, SessionScore, GamePhase)
│   │   ├── WordBank.swift             (WordPair, Difficulty, word bank data)
│   │   └── GameSettings.swift         (GameSettings struct)
│   ├── Services/
│   │   ├── SupabaseService.swift      (Supabase client, CRUD, realtime)
│   │   └── WordGeneratorService.swift (AI word generation via edge function)
│   ├── Utilities/
│   │   ├── GameUtils.swift            (code gen, shuffle, parse helpers)
│   │   └── ClueRound.swift            (clue round state machine)
│   ├── ViewModels/
│   │   └── GameViewModel.swift        (ObservableObject, all game logic)
│   ├── Views/
│   │   ├── HomeScreen.swift
│   │   ├── LobbyScreen.swift
│   │   ├── RoleRevealScreen.swift
│   │   ├── CluePhaseScreen.swift
│   │   ├── VotingScreen.swift
│   │   └── ResultsScreen.swift
│   ├── Components/
│   │   ├── PillButton.swift
│   │   ├── WaitingIndicator.swift
│   │   └── SegmentedControl.swift
│   └── Theme/
│       └── AppTheme.swift             (colors, fonts, shadows)
```

## Key Architecture Decisions

1. **Supabase Swift SDK** - Use `supabase-swift` package for native Supabase integration
2. **ObservableObject ViewModel** - Single GameViewModel mirrors useGame hook
3. **Phase-based navigation** - ContentView switches on game.phase, same as web
4. **Realtime** - Supabase Realtime channels for game/player updates
5. **Local word bank** - Embedded in app, same 400+ words
6. **Scoring** - Client-side scoring logic, same as web (session scores in memory)

## Supabase Credentials
- URL: https://mrievkfloftgpcmvjgwb.supabase.co
- Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

## Color System (HSL → SwiftUI)
- Background: HSL(40, 30%, 98%) → cream/off-white
- Primary: HSL(250, 84%, 54%) → electric indigo
- Destructive: HSL(0, 84%, 60%) → red
- Muted: HSL(230, 10%, 45%) → gray
- Secondary: HSL(40, 20%, 92%) → light cream
