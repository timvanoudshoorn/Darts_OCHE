import Foundation

/// State for the 170 Practice (WDA) drill: a single shared running score
/// starting at 170. Each player throws up to 3 darts trying to check it out
/// under standard double-out rules:
/// - A **bust** (overshoot, leaves exactly 1, or hits 0 without a double)
///   reverts the shared score to what it was at the start of *this player's*
///   turn, and passes it on unchanged.
/// - A successful **checkout** finishes the round for that player (their
///   `roundsFinished` count goes up) and immediately resets the shared score
///   to 170 — any leftover darts in that same turn are thrown at the fresh 170.
/// - Otherwise the reduced score simply passes to the next player.
struct Practice170State: Codable, Equatable {
    var players: [GamePlayer]

    var sharedScore: Int = 170
    /// The shared score at the moment the current player's turn began —
    /// used to revert on a bust.
    var scoreAtTurnStart: Int = 170

    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []

    var roundsFinished: [Int]
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var isSessionOver: Bool = false

    init(players: [GamePlayer]) {
        self.players = players
        self.roundsFinished = players.map { _ in 0 }
        self.turnsCompleted = players.map { _ in 0 }
    }
}

enum Practice170Outcome: Equatable {
    case normal
    case bust
    case checkout
    case turnComplete
}

final class Practice170Engine: GameEngineBase<Practice170State> {

    init(players: [GamePlayer]) {
        super.init(initialState: Practice170State(players: players))
    }

    var players: [GamePlayer] { current.players }
    var sharedScore: Int { current.sharedScore }
    var currentPlayerIndex: Int { current.currentPlayerIndex }
    var currentPlayer: GamePlayer { current.players[current.currentPlayerIndex] }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var isSessionOver: Bool { current.isSessionOver }
    var dartLog: [DartLogEntry] { current.dartLog }

    func roundsFinished(for player: Int) -> Int { current.roundsFinished[player] }

    /// Checkout suggestions for the current shared score — a few alternative
    /// same-dart-count routes when more than one exists.
    var checkoutSuggestions: [CheckoutTable.Suggestion] {
        CheckoutTable.suggestions(for: current.sharedScore)
    }

    @discardableResult
    func throwDart(_ dart: Dart) -> Practice170Outcome {
        guard !isSessionOver else { return .normal }
        var outcome: Practice170Outcome = .normal

        mutate { state in
            let p = state.currentPlayerIndex
            let before = state.sharedScore
            let newRemaining = before - dart.points

            let isBust = newRemaining < 0
                || newRemaining == 1
                || (newRemaining == 0 && !dart.isDouble)

            state.currentTurnDarts.append(dart)
            state.dartLog.append(DartLogEntry(
                playerIndex: p, turnIndex: state.turnsCompleted[p], dart: dart,
                isBust: isBust,
                isCheckoutAttempt: CheckoutTable.isCheckoutPossible(before),
                isCheckoutHit: !isBust && newRemaining == 0
            ))

            if isBust {
                outcome = .bust
                state.sharedScore = state.scoreAtTurnStart
            } else if newRemaining == 0 {
                outcome = .checkout
                state.roundsFinished[p] += 1
                state.sharedScore = 170
                state.scoreAtTurnStart = 170
            } else {
                state.sharedScore = newRemaining
            }

            if state.currentTurnDarts.count >= 3 {
                if outcome == .normal { outcome = .turnComplete }
                state.turnsCompleted[p] += 1
                state.currentTurnDarts = []
                state.currentPlayerIndex = (p + 1) % state.players.count
                state.scoreAtTurnStart = state.sharedScore
            }
        }

        return outcome
    }

    /// Manually ends the practice session (e.g. user taps "Finish").
    func endSession() {
        mutate { state in
            state.isSessionOver = true
        }
    }
}
