import Foundation

/// State for Count-Up: everyone throws the same number of rounds (default 7),
/// highest cumulative total wins.
struct CountUpState: Codable, Equatable {
    var players: [GamePlayer]
    var totalRounds: Int

    var scores: [Int]
    var currentRound: Int = 0
    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var winnerIndex: Int? = nil

    var isGameOver: Bool { winnerIndex != nil }

    init(players: [GamePlayer], totalRounds: Int) {
        self.players = players
        self.totalRounds = totalRounds
        self.scores = players.map { _ in 0 }
        self.turnsCompleted = players.map { _ in 0 }
    }
}

final class CountUpEngine: GameEngineBase<CountUpState> {

    init(players: [GamePlayer], totalRounds: Int = 7) {
        super.init(initialState: CountUpState(players: players, totalRounds: totalRounds))
    }

    var players: [GamePlayer] { current.players }
    var scores: [Int] { current.scores }
    var totalRounds: Int { current.totalRounds }
    var currentRound: Int { current.currentRound }
    var currentPlayerIndex: Int { current.currentPlayerIndex }
    var currentPlayer: GamePlayer { current.players[current.currentPlayerIndex] }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var winnerIndex: Int? { current.winnerIndex }
    var isGameOver: Bool { current.isGameOver }
    var dartLog: [DartLogEntry] { current.dartLog }

    @discardableResult
    func throwDart(_ dart: Dart) -> Bool {
        guard !isGameOver else { return false }
        var gameEnded = false

        mutate { state in
            let p = state.currentPlayerIndex
            state.scores[p] += dart.points
            state.currentTurnDarts.append(dart)
            state.dartLog.append(DartLogEntry(playerIndex: p, turnIndex: state.currentRound, dart: dart))

            guard state.currentTurnDarts.count >= 3 else { return }

            state.turnsCompleted[p] += 1
            state.currentTurnDarts = []

            if p == state.players.count - 1 {
                state.currentRound += 1
                state.currentPlayerIndex = 0
                if state.currentRound >= state.totalRounds {
                    let best = state.scores.max() ?? 0
                    state.winnerIndex = state.scores.firstIndex(of: best)
                    gameEnded = true
                }
            } else {
                state.currentPlayerIndex = p + 1
            }
        }

        return gameEnded
    }
}
