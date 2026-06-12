import Foundation

/// A single round's target in Halve-It.
enum HalveItTarget: Codable, Equatable, Hashable {
    /// A specific segment (1-20, or 25 for Bull) — any multiplier scores.
    case number(Int)
    /// Score from any darts landing on a double (any number).
    case anyDouble
    /// Score from any darts landing on a triple (any number).
    case anyTriple

    var label: String {
        switch self {
        case .number(25): return "Bull"
        case .number(let n): return "\(n)"
        case .anyDouble: return "Any Double"
        case .anyTriple: return "Any Triple"
        }
    }
}

/// State for Halve-It. Each round has a target; if a player's 3 darts score
/// nothing against that round's target, their running total is halved
/// (rounded down). Highest total after all rounds wins.
struct HalveItState: Codable, Equatable {
    /// Default 7-round sequence used by the prototype.
    static let defaultTargets: [HalveItTarget] = [
        .number(20), .number(19), .anyDouble, .number(18), .number(17), .anyTriple, .number(25)
    ]

    var players: [GamePlayer]
    var targets: [HalveItTarget]

    var scores: [Int]
    var currentRound: Int = 0
    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var winnerIndex: Int? = nil

    var isGameOver: Bool { winnerIndex != nil }
    var currentTarget: HalveItTarget { targets[currentRound] }

    init(players: [GamePlayer], targets: [HalveItTarget] = HalveItState.defaultTargets) {
        self.players = players
        self.targets = targets
        self.scores = players.map { _ in 0 }
        self.turnsCompleted = players.map { _ in 0 }
    }
}

enum HalveItOutcome: Equatable {
    case normal
    case roundScored(points: Int)
    case halved(newScore: Int)
    case gameOver
}

final class HalveItEngine: GameEngineBase<HalveItState> {

    init(players: [GamePlayer], targets: [HalveItTarget] = HalveItState.defaultTargets) {
        super.init(initialState: HalveItState(players: players, targets: targets))
    }

    var players: [GamePlayer] { current.players }
    var targets: [HalveItTarget] { current.targets }
    var scores: [Int] { current.scores }
    var currentRound: Int { current.currentRound }
    var currentTarget: HalveItTarget { current.currentTarget }
    var currentPlayerIndex: Int { current.currentPlayerIndex }
    var currentPlayer: GamePlayer { current.players[current.currentPlayerIndex] }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var winnerIndex: Int? { current.winnerIndex }
    var isGameOver: Bool { current.isGameOver }
    var dartLog: [DartLogEntry] { current.dartLog }

    private func points(of dart: Dart, toward target: HalveItTarget) -> Int {
        switch target {
        case .number(let n):
            return dart.value == n ? dart.points : 0
        case .anyDouble:
            return dart.isDouble ? dart.points : 0
        case .anyTriple:
            return dart.multiplier == .triple && dart.points > 0 ? dart.points : 0
        }
    }

    @discardableResult
    func throwDart(_ dart: Dart) -> HalveItOutcome {
        guard !isGameOver else { return .normal }
        var outcome: HalveItOutcome = .normal

        mutate { state in
            let p = state.currentPlayerIndex
            state.currentTurnDarts.append(dart)
            state.dartLog.append(DartLogEntry(playerIndex: p, turnIndex: state.currentRound, dart: dart))

            guard state.currentTurnDarts.count >= 3 else { return }

            let target = state.currentTarget
            let earned = state.currentTurnDarts.reduce(0) { $0 + self.points(of: $1, toward: target) }

            if earned > 0 {
                state.scores[p] += earned
                outcome = .roundScored(points: earned)
            } else {
                state.scores[p] = state.scores[p] / 2
                outcome = .halved(newScore: state.scores[p])
            }

            state.turnsCompleted[p] += 1
            state.currentTurnDarts = []

            if p == state.players.count - 1 {
                state.currentRound += 1
                state.currentPlayerIndex = 0
                if state.currentRound >= state.targets.count {
                    let best = state.scores.max() ?? 0
                    state.winnerIndex = state.scores.firstIndex(of: best)
                    outcome = .gameOver
                }
            } else {
                state.currentPlayerIndex = p + 1
            }
        }

        return outcome
    }
}
