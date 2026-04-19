import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let game = viewModel.game, viewModel.currentPlayer != nil {
                switch game.phase {
                case .lobby:
                    LobbyScreen(viewModel: viewModel)
                case .roleReveal:
                    RoleRevealScreen(viewModel: viewModel)
                case .clueGiving:
                    CluePhaseScreen(viewModel: viewModel)
                case .voting:
                    VotingScreen(viewModel: viewModel)
                case .results:
                    ResultsScreen(viewModel: viewModel)
                }
            } else {
                HomeScreen(viewModel: viewModel)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.game?.phase)

        .onDisappear {
            viewModel.cleanup()
        }
    }
}
