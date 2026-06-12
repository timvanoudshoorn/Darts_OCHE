import Foundation

/// State for Standard Darts (301 / 501), double-out.
struct X01State: Codable, Equatable {
    var players: [GamePlayer]
    var startingScore: Int

    /// Remaining score per player.
    var scores: [Int]
    /// Score this player had at the start of the *current* turn — used to
    /// revert a bust to exactly where the turn began.
    var scoreAtTurnStart: Int

    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []

    /// Number of *completed* turns per player, used to tag `DartLogEntry.turnIndex`
    /// for stats like the first-9 average.
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var winnerIndex: Int? = nil

    var isGameOver: Bool { winnerIndex != nil }

    init(players: [GamePlayer], startingScore: Int) {
        self.players = players
        self.startingScore = startingScore
        self.scores = players.map { _ in startingScore }
        self.scoreAtTurnStart = startingScore
        self.turnsCompleted = players.map { _ in 0 }
    }
}

/// Result of a single dart throw, used by the UI to drive popups/animations.
enum X01ThrowOutcome: Equatable {
    case normal
    case bust
    case checkout
    case turnComplete
}

final class X01Engine: GameEngineBase<X01State> {

    init(players: [GamePlayer], startingScore: Int) {
        super.init(initialState: X01State(players: players, startingScore: startingScore))
    }

    var players: [GamePlayer] { current.players }
    var scores: [Int] { current.scores }
    var currentPlayerIndex: Int { current.currentPlayerIndex }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var winnerIndex: Int? { current.winnerIndex }
    var isGameOver: Bool { current.isGameOver }
    var dartLog: [DartLogEntry] { current.dartLog }

    var currentPlayer: GamePlayer { current.players[current.currentPlayerIndex] }

    func remaining(for playerIndex: Int) -> Int { current.scores[playerIndex] }

    /// Checkout suggestion for the active player's current remaining score.
    var checkoutSuggestion: CheckoutTable.Suggestion? {
        CheckoutTable.suggestion(for: current.scores[current.currentPlayerIndex])
    }

    /// Throws a dart for the current player. Returns the outcome so the UI can
    /// trigger the right popup/animation.
    @discardableResult
    func throwDart(_ dart: Dart) -> X01ThrowOutcome {
        guard !isGameOver else { return .normal }

        var outcome: X01ThrowOutcome = .normal

        mutate { state in
            let playerIndex = state.currentPlayerIndex
            let remainingBefore = state.scores[playerIndex]
            let newRemaining = remainingBefore - dart.points

            let isBust = newRemaining < 0
                || newRemaining == 1
                || (newRemaining == 0 && !dart.isDouble)

            let entry = DartLogEntry(
                playerIndex: playerIndex,
                turnIndex: state.turnsCompleted[playerIndex],
                dart: dart,
                isBust: isBust,
                isCheckoutAttempt: CheckoutTable.isCheckoutPossible(remainingBefore),
                isCheckoutHit: !isBust && newRemaining == 0
            )

            state.currentTurnDarts.append(dart)
            state.dartLog.append(entry)

            if isBust {
                outcome = .bust
                state.scores[playerIndex] = state.scoreAtTurnStart
                endTurn(&state)
            } else if newRemaining == 0 {
                outcome = .checkout
                state.scores[playerIndex] = 0
                state.winnerIndex = playerIndex
                state.turnsCompleted[playerIndex] += 1
            } else {
                state.scores[playerIndex] = newRemaining
                if state.currentTurnDarts.count >= 3 {
                    outcome = .turnComplete
                    endTurn(&state)
                }
            }
        }

        return outcome
    }

    /// Ends the current player's turn, advancing to the next player.
    private func endTurn(_ state: inout X01State) {
        let playerIndex = state.currentPlayerIndex
        state.turnsCompleted[playerIndex] += 1
        state.currentTurnDarts = []
        let next = (playerIndex + 1) % state.players.count
        state.currentPlayerIndex = next
        state.scoreAtTurnStart = state.scores[next]
    }

    /// True if a hypothetical dart would bust the current player — used to
    /// dim the number pad button red for "would bust".
    func wouldBust(_ dart: Dart) -> Bool {
        let remaining = current.scores[current.currentPlayerIndex]
        let newRemaining = remaining - dart.points
        return newRemaining < 0 || newRemaining == 1 || (newRemaining == 0 && !dart.isDouble)
    }

    /// True if a hypothetical dart would be the exact checkout — used to make
    /// the button glow/pulse with "OUT ✓".
    func wouldCheckout(_ dart: Dart) -> Bool {
        let remaining = current.scores[current.currentPlayerIndex]
        return remaining - dart.points == 0 && dart.isDouble
    }
}
