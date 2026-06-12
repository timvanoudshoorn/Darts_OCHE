import Foundation

/// State for Killer.
///
/// Rules implemented:
/// - **Assignment ("bull-off")**: each player throws one dart in turn. Landing on
///   an unclaimed number 1-20 assigns that as their number (heart icon). Misses,
///   Bull, or an already-claimed number don't count — that player throws again.
/// - **Going live**: hitting your own number adds marks equal to the multiplier
///   (capped at 3). At 3 marks you "go live" — heart becomes a skull.
/// - **Killing**: once live, hitting *any other player's* number removes lives
///   equal to the multiplier (single = -1, double = -2, triple = -3).
/// - **Self-damage**: once live, hitting your *own* number again removes lives
///   from yourself by the multiplier — going live makes your own number
///   dangerous too, the classic Killer risk/reward.
/// - **Win**: last player with lives remaining wins.
struct KillerState: Codable, Equatable {
    enum Phase: Codable, Equatable {
        case assignment
        case playing
    }

    var players: [GamePlayer]
    var startingLives: Int

    /// Each player's assigned board number (1-20), or `nil` until assigned.
    var assignedNumber: [Int?]
    /// Progress toward going live (0...3).
    var marks: [Int]
    var isLive: [Bool]
    var lives: [Int]

    var phase: Phase = .assignment
    /// Whose turn it is during the assignment ("bull-off") phase.
    var assignmentPlayerIndex: Int = 0

    var currentPlayerIndex: Int = 0
    var currentTurnDarts: [Dart] = []
    var turnsCompleted: [Int]

    var dartLog: [DartLogEntry] = []
    var winnerIndex: Int? = nil

    var isGameOver: Bool { winnerIndex != nil }

    init(players: [GamePlayer], startingLives: Int = 3) {
        self.players = players
        self.startingLives = startingLives
        self.assignedNumber = players.map { _ in nil }
        self.marks = players.map { _ in 0 }
        self.isLive = players.map { _ in false }
        self.lives = players.map { _ in startingLives }
        self.turnsCompleted = players.map { _ in 0 }
    }
}

final class KillerEngine: GameEngineBase<KillerState> {

    init(players: [GamePlayer], startingLives: Int = 3) {
        super.init(initialState: KillerState(players: players, startingLives: startingLives))
    }

    var players: [GamePlayer] { current.players }
    var phase: KillerState.Phase { current.phase }
    var currentPlayerIndex: Int { current.phase == .assignment ? current.assignmentPlayerIndex : current.currentPlayerIndex }
    var currentPlayer: GamePlayer { current.players[currentPlayerIndex] }
    var currentTurnDarts: [Dart] { current.currentTurnDarts }
    var winnerIndex: Int? { current.winnerIndex }
    var isGameOver: Bool { current.isGameOver }
    var dartLog: [DartLogEntry] { current.dartLog }

    func assignedNumber(for player: Int) -> Int? { current.assignedNumber[player] }
    func marks(for player: Int) -> Int { current.marks[player] }
    func isLive(_ player: Int) -> Bool { current.isLive[player] }
    func lives(for player: Int) -> Int { current.lives[player] }

    /// Throws one dart during the bull-off assignment phase. If `dart` lands on
    /// an unclaimed number 1-20, that player is assigned the number and the
    /// bull-off moves to the next player; otherwise nothing changes (rethrow).
    @discardableResult
    func throwAssignmentDart(_ dart: Dart) -> Bool {
        guard current.phase == .assignment else { return false }
        var assigned = false

        mutate { state in
            let p = state.assignmentPlayerIndex
            if dart.value >= 1, dart.value <= 20, !state.assignedNumber.contains(dart.value) {
                state.assignedNumber[p] = dart.value
                assigned = true
                if p == state.players.count - 1 {
                    state.phase = .playing
                } else {
                    state.assignmentPlayerIndex = p + 1
                }
            }
        }

        return assigned
    }

    /// Throws one dart during normal play.
    @discardableResult
    func throwDart(_ dart: Dart) -> Bool {
        guard current.phase == .playing, !isGameOver else { return false }
        var gameEnded = false

        mutate { state in
            let p = state.currentPlayerIndex
            state.currentTurnDarts.append(dart)

            if dart.value >= 1, dart.value <= 20, dart.points > 0,
               let targetIdx = state.assignedNumber.firstIndex(of: dart.value) {

                if targetIdx == p {
                    if !state.isLive[p] {
                        state.marks[p] = min(3, state.marks[p] + dart.multiplier.rawValue)
                        if state.marks[p] >= 3 { state.isLive[p] = true }
                    } else {
                        state.lives[p] = max(0, state.lives[p] - dart.multiplier.rawValue)
                    }
                } else if state.isLive[p] {
                    state.lives[targetIdx] = max(0, state.lives[targetIdx] - dart.multiplier.rawValue)
                }
            }

            state.dartLog.append(DartLogEntry(playerIndex: p, turnIndex: state.turnsCompleted[p], dart: dart))

            let alive = state.players.indices.filter { state.lives[$0] > 0 }
            if alive.count <= 1 {
                state.winnerIndex = alive.first ?? p
                gameEnded = true
            } else if state.currentTurnDarts.count >= 3 {
                state.turnsCompleted[p] += 1
                state.currentTurnDarts = []
                var next = (p + 1) % state.players.count
                while state.lives[next] == 0, next != p {
                    next = (next + 1) % state.players.count
                }
                state.currentPlayerIndex = next
            }
        }

        return gameEnded
    }
}
