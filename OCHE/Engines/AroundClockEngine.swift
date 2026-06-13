import Foundation

/// State for Around the Clock: race through a sequence of targets (1-20, optionally
/// + Bull, optionally reversed).
struct AroundClockState: Codable, Equatable {
    var players: [GamePlayer]

    /// The ordered list of target segment values a player must hit, in order.
    /// `25` represents Bull. Built once at game start from the configured options.
    var sequence: [Int]

    /// If true, a double/triple hit advances the player multiple steps at once
    /// (e.g. hitting T5 while target is 5 advances through 5, 6 and 7).
    var multipliersCount: Bool

    /// Index into `sequence` for each player — `sequence.count` means finished.
    var progress: [Int]

    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var winnerIndex: Int? = nil

    var isGameOver: Bool { winnerIndex != nil }

    init(players: [GamePlayer], finishOnBull: Bool, multipliersCount: Bool, reverse: Bool) {
        self.players = players
        self.multipliersCount = multipliersCount

        var seq = Array(1...20)
        if reverse { seq.reverse() }
        if finishOnBull {
            if reverse {
                seq = [25] + seq
            } else {
                seq = seq + [25]
            }
        }
        self.sequence = seq

        self.progress = players.map { _ in 0 }
        self.turnsCompleted = players.map { _ in 0 }
    }

    /// The current target for `player`, or `nil` if they've finished.
    func currentTarget(for player: Int) -> Int? {
        let idx = progress[player]
        guard idx < sequence.count else { return nil }
        return sequence[idx]
    }
}

final class AroundClockEngine: GameEngineBase<AroundClockState> {

    init(players: [GamePlayer], finishOnBull: Bool, multipliersCount: Bool, reverse: Bool) {
        super.init(initialState: AroundClockState(
            players: players, finishOnBull: finishOnBull,
            multipliersCount: multipliersCount, reverse: reverse
        ))
    }

    var players: [GamePlayer] { current.players }
    var multipliersCount: Bool { current.multipliersCount }
    var sequence: [Int] { current.sequence }
    var progress: [Int] { current.progress }
    var currentPlayerIndex: Int { current.currentPlayerIndex }
    var currentPlayer: GamePlayer { current.players[current.currentPlayerIndex] }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var winnerIndex: Int? { current.winnerIndex }
    var isGameOver: Bool { current.isGameOver }
    var dartLog: [DartLogEntry] { current.dartLog }

    func currentTarget(for player: Int) -> Int? { current.currentTarget(for: player) }

    /// `true` if `dart` matches the active player's current target — used to
    /// highlight the matching number pad button.
    func isOnTarget(_ dart: Dart) -> Bool {
        guard let target = currentTarget(for: currentPlayerIndex) else { return false }
        return dart.value == target && dart.points > 0
    }

    @discardableResult
    func throwDart(_ dart: Dart) -> Bool {
        guard !isGameOver else { return false }
        var finished = false

        mutate { state in
            let p = state.currentPlayerIndex
            state.currentTurnDarts.append(dart)

            var hit = false
            if let target = state.currentTarget(for: p), dart.value == target, dart.points > 0 {
                let advance = state.multipliersCount ? dart.multiplier.rawValue : 1
                state.progress[p] = min(state.sequence.count, state.progress[p] + advance)
                hit = true
            }

            let willFinish = state.progress[p] >= state.sequence.count
            let entry = DartLogEntry(
                playerIndex: p, turnIndex: state.turnsCompleted[p], dart: dart,
                isCheckoutHit: hit && willFinish
            )
            state.dartLog.append(entry)

            if willFinish {
                state.winnerIndex = p
                state.turnsCompleted[p] += 1
                finished = true
            } else if state.currentTurnDarts.count >= 3 {
                state.turnsCompleted[p] += 1
                state.currentTurnDarts = []
                state.currentPlayerIndex = (p + 1) % state.players.count
            }
        }

        return finished
    }
}
