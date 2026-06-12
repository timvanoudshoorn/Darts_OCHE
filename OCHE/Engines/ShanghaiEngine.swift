import Foundation

/// State for Shanghai. Round `r` (1-based) targets the number `r`; hitting
/// single, double AND triple of that number in the same visit ("a Shanghai")
/// is an instant win. Otherwise highest total after `totalRounds` wins.
struct ShanghaiState: Codable, Equatable {
    var players: [GamePlayer]
    var totalRounds: Int

    var scores: [Int]
    var currentRound: Int = 0
    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var winnerIndex: Int? = nil
    var isShanghaiWin: Bool = false

    var isGameOver: Bool { winnerIndex != nil }

    /// The number this round is targeting (1-based).
    var target: Int { currentRound + 1 }

    init(players: [GamePlayer], totalRounds: Int) {
        self.players = players
        self.totalRounds = totalRounds
        self.scores = players.map { _ in 0 }
        self.turnsCompleted = players.map { _ in 0 }
    }
}

enum ShanghaiOutcome: Equatable {
    case normal
    case shanghaiWin
    case roundsComplete
}

final class ShanghaiEngine: GameEngineBase<ShanghaiState> {

    init(players: [GamePlayer], totalRounds: Int = 7) {
        super.init(initialState: ShanghaiState(players: players, totalRounds: totalRounds))
    }

    var players: [GamePlayer] { current.players }
    var scores: [Int] { current.scores }
    var totalRounds: Int { current.totalRounds }
    var currentRound: Int { current.currentRound }
    var target: Int { current.target }
    var currentPlayerIndex: Int { current.currentPlayerIndex }
    var currentPlayer: GamePlayer { current.players[current.currentPlayerIndex] }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var winnerIndex: Int? { current.winnerIndex }
    var isGameOver: Bool { current.isGameOver }
    var isShanghaiWin: Bool { current.isShanghaiWin }
    var dartLog: [DartLogEntry] { current.dartLog }

    @discardableResult
    func throwDart(_ dart: Dart) -> ShanghaiOutcome {
        guard !isGameOver else { return .normal }
        var outcome: ShanghaiOutcome = .normal

        mutate { state in
            let p = state.currentPlayerIndex
            let target = state.target

            if dart.value == target, dart.points > 0 {
                state.scores[p] += dart.points
            }
            state.currentTurnDarts.append(dart)
            state.dartLog.append(DartLogEntry(playerIndex: p, turnIndex: state.currentRound, dart: dart))

            guard state.currentTurnDarts.count >= 3 else { return }

            let hitMultipliers = Set(
                state.currentTurnDarts
                    .filter { $0.value == target && $0.points > 0 }
                    .map { $0.multiplier }
            )

            if hitMultipliers == Set(Multiplier.allCases) {
                state.winnerIndex = p
                state.isShanghaiWin = true
                outcome = .shanghaiWin
                return
            }

            state.turnsCompleted[p] += 1
            state.currentTurnDarts = []

            if p == state.players.count - 1 {
                state.currentRound += 1
                state.currentPlayerIndex = 0
                if state.currentRound >= state.totalRounds {
                    let best = state.scores.max() ?? 0
                    state.winnerIndex = state.scores.firstIndex(of: best)
                    outcome = .roundsComplete
                }
            } else {
                state.currentPlayerIndex = p + 1
            }
        }

        return outcome
    }
}
