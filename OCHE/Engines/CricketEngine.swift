import Foundation

/// State for Cricket: numbers 20-15 + Bull, close-and-score-out.
struct CricketState: Codable, Equatable {
    /// Display order: 20 down to 15, then Bull.
    static let numbers: [Int] = [20, 19, 18, 17, 16, 15, 25]

    var players: [GamePlayer]

    /// marks[playerIndex][number] -> 0...3 (closed at 3).
    var marks: [[Int: Int]]
    var scores: [Int]

    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var winnerIndex: Int? = nil

    var isGameOver: Bool { winnerIndex != nil }

    init(players: [GamePlayer]) {
        self.players = players
        self.marks = players.map { _ in [:] }
        self.scores = players.map { _ in 0 }
        self.turnsCompleted = players.map { _ in 0 }
    }

    func marks(player: Int, number: Int) -> Int {
        marks[player][number] ?? 0
    }

    func isClosed(player: Int, number: Int) -> Bool {
        marks(player: player, number: number) >= 3
    }

    /// Whether `number` is closed by every player except `excluding`.
    func isClosedByAllOthers(number: Int, excluding player: Int) -> Bool {
        players.indices.filter { $0 != player }.allSatisfy { isClosed(player: $0, number: number) }
    }
}

final class CricketEngine: GameEngineBase<CricketState> {

    init(players: [GamePlayer]) {
        super.init(initialState: CricketState(players: players))
    }

    var players: [GamePlayer] { current.players }
    var scores: [Int] { current.scores }
    var currentPlayerIndex: Int { current.currentPlayerIndex }
    var currentPlayer: GamePlayer { current.players[current.currentPlayerIndex] }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var winnerIndex: Int? { current.winnerIndex }
    var isGameOver: Bool { current.isGameOver }
    var dartLog: [DartLogEntry] { current.dartLog }

    func marks(player: Int, number: Int) -> Int { current.marks(player: player, number: number) }
    func isClosed(player: Int, number: Int) -> Bool { current.isClosed(player: player, number: number) }

    /// `true` if hitting `dart` right now would score points (open number not
    /// closed by all opponents), used to drive number pad highlighting.
    func wouldScore(_ dart: Dart) -> Bool {
        guard CricketState.numbers.contains(dart.value), dart.points > 0 else { return false }
        let p = current.currentPlayerIndex
        let already = current.marks(player: p, number: dart.value)
        let extra = max(0, (already + dart.multiplier.rawValue) - 3)
        guard extra > 0 else { return false }
        return !current.isClosedByAllOthers(number: dart.value, excluding: p)
    }

    @discardableResult
    func throwDart(_ dart: Dart) -> Bool {
        guard !isGameOver else { return false }
        var didCheckout = false

        mutate { state in
            let p = state.currentPlayerIndex
            state.currentTurnDarts.append(dart)

            let entry = DartLogEntry(playerIndex: p, turnIndex: state.turnsCompleted[p], dart: dart)

            if CricketState.numbers.contains(dart.value), dart.points > 0 {
                let number = dart.value
                let mult = dart.multiplier.rawValue
                let current = state.marks[p][number] ?? 0
                let newMarks = min(3, current + mult)
                let extra = (current + mult) - newMarks
                state.marks[p][number] = newMarks

                if extra > 0, !state.isClosedByAllOthers(number: number, excluding: p) {
                    let value = number == 25 ? 25 : number
                    state.scores[p] += extra * value
                }
            }

            state.dartLog.append(entry)

            // Win check: all numbers closed AND score >= every opponent's score.
            let closedAll = CricketState.numbers.allSatisfy { state.isClosed(player: p, number: $0) }
            if closedAll {
                let maxOther = state.players.indices.filter { $0 != p }.map { state.scores[$0] }.max() ?? 0
                if state.scores[p] >= maxOther {
                    state.winnerIndex = p
                    didCheckout = true
                }
            }

            if !state.isGameOver, state.currentTurnDarts.count >= 3 {
                state.turnsCompleted[p] += 1
                state.currentTurnDarts = []
                state.currentPlayerIndex = (p + 1) % state.players.count
            } else if state.isGameOver {
                state.turnsCompleted[p] += 1
            }
        }

        return didCheckout
    }
}
