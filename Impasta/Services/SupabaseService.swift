import Foundation
import Supabase
import Realtime

// MARK: - Supabase Service
@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        let url = URL(string: "https://mrievkfloftgpcmvjgwb.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yaWV2a2Zsb2Z0Z3BjbXZqZ3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMzk1NzksImV4cCI6MjA4OTcxNTU3OX0._iXWHIXJTmLWBZNphksOcn6jemqEfer1eCeKx7velJg"
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // MARK: - Game Operations

    func createGame(code: String) async throws -> Game {
        let values: [String: AnyJSON] = [
            "code": .string(code),
            "phase": .string("lobby"),
        ]
        let response: Game = try await client
            .from("games")
            .insert(values)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func fetchGame(byCode code: String) async throws -> Game {
        let response: Game = try await client
            .from("games")
            .select()
            .eq("code", value: code)
            .single()
            .execute()
            .value
        return response
    }

    func fetchGameById(_ id: String) async throws -> Game {
        let response: Game = try await client
            .from("games")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return response
    }

    func updateGame(id: String, values: [String: AnyJSON]) async throws {
        try await client
            .from("games")
            .update(values)
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Player Operations

    func createPlayer(gameId: String, name: String, isHost: Bool = false) async throws -> Player {
        let values: [String: AnyJSON] = [
            "game_id": .string(gameId),
            "name": .string(name),
            "is_host": .bool(isHost),
        ]
        let response: Player = try await client
            .from("players")
            .insert(values)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func fetchPlayers(gameId: String) async throws -> [Player] {
        let response: [Player] = try await client
            .from("players")
            .select()
            .eq("game_id", value: gameId)
            .order("turn_order", ascending: true, nullsFirst: false)
            .execute()
            .value
        return response
    }

    func updatePlayer(id: String, values: [String: AnyJSON]) async throws {
        try await client
            .from("players")
            .update(values)
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Realtime Subscriptions

    func subscribeToGame(
        gameId: String,
        onGameUpdate: @escaping @MainActor (Game) -> Void,
        onPlayersUpdate: @escaping @MainActor () -> Void
    ) -> RealtimeChannelV2 {
        let channel = client.realtimeV2.channel("game-\(gameId)")

        // Listen for game table changes using the new filter syntax
        let gameChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "games",
            filter: .eq("id", value: gameId)
        )

        // Listen for player table changes using the new filter syntax
        let playerChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "players",
            filter: .eq("game_id", value: gameId)
        )

        Task { @MainActor in
            try? await channel.subscribeWithError()

            // Game changes listener
            Task {
                for await _ in gameChanges {
                    // Re-fetch to ensure full model consistency
                    if let freshGame = try? await SupabaseService.shared.fetchGameById(gameId) {
                        await MainActor.run { onGameUpdate(freshGame) }
                    }
                }
            }

            // Player changes listener
            Task {
                for await _ in playerChanges {
                    await MainActor.run { onPlayersUpdate() }
                }
            }
        }

        return channel
    }

    func unsubscribe(channel: RealtimeChannelV2) {
        Task {
            await channel.unsubscribe()
        }
    }

    // MARK: - Edge Function (AI Word Generation)

    func invokeGenerateWord(difficulty: String, excludeWords: [String]) async throws -> (word: String, imposterClue: String)? {
        let body: [String: AnyJSON] = [
            "difficulty": .string(difficulty),
            "excludeWords": .array(excludeWords.map { .string($0) }),
        ]

        // In latest SDK, invoke returns Data directly
        let data: Data = try await client.functions.invoke(
            "generate-word",
            options: .init(body: body)
        )

        struct WordResponse: Decodable {
            let word: String
            let imposterClue: String
        }

        // Use data directly to decode
        guard let result = try? JSONDecoder().decode(WordResponse.self, from: data) else {
            return nil
        }

        return (word: result.word.lowercased(), imposterClue: result.imposterClue)
    }
}
