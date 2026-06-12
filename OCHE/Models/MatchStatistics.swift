import Foundation

/// Per-player statistics derived from a `DartLogEntry` array, recomputed from
/// scratch any time it's needed (including after Undo, so stats always match
/// the current game state exactly).
///
/// **Formulas** (3-dart darts convention):
/// - A "turn" is the group of darts a player threw consecutively, identified
///   by `(playerIndex, turnIndex)`.
/// - A turn's `points` is the sum of its darts' `points` — unless any dart in
///   the turn is marked `isBust`, in which case the turn contributes **0**
///   (the score reverted, so nothing was actually scored).
/// - `threeDartAverage = totalScoredPoints / totalDartsThrown * 3`
/// - `firstNineAverage` is the same formula restricted to `turnIndex < 3`
///   (the player's first three turns, i.e. up to their first 9 darts).
/// - `checkoutPercentage = checkoutHits / checkoutAttempts * 100`, where a
///   "checkout attempt" is any dart thrown while the remaining score had a
///   possible double-out finish.
/// - `oneEightys`, `oneFortyPlus`, `oneHundredPlus` count turns whose points
///   are `== 180`, `>= 140`, and `>= 100` respectively (a 180 also counts
///   toward the other two buckets, matching standard scoreboard conventions).
struct MatchStatistics: Equatable, Codable {
    var playerIndex: Int
    var dartsThrown: Int
    var totalScoredPoints: Int
    var threeDartAverage: Double
    var firstNineAverage: Double
    var checkoutAttempts: Int
    var checkoutHits: Int
    var checkoutPercentage: Double
    var highestTurn: Int
    var oneHundredPlus: Int
    var oneFortyPlus: Int
    var oneEightys: Int

    static func compute(from dartLog: [DartLogEntry], playerIndex: Int) -> MatchStatistics {
        let entries = dartLog.filter { $0.playerIndex == playerIndex }

        let dartsThrown = entries.count
        let checkoutAttempts = entries.filter { $0.isCheckoutAttempt }.count
        let checkoutHits = entries.filter { $0.isCheckoutHit }.count
        let checkoutPercentage = checkoutAttempts > 0
            ? Double(checkoutHits) / Double(checkoutAttempts) * 100
            : 0

        // Group into turns, preserving encounter order.
        var turnOrder: [Int] = []
        var turnDarts: [Int: [DartLogEntry]] = [:]
        for entry in entries {
            if turnDarts[entry.turnIndex] == nil {
                turnDarts[entry.turnIndex] = []
                turnOrder.append(entry.turnIndex)
            }
            turnDarts[entry.turnIndex]!.append(entry)
        }

        var totalScoredPoints = 0
        var highestTurn = 0
        var oneHundredPlus = 0
        var oneFortyPlus = 0
        var oneEightys = 0
        var firstNinePoints = 0
        var firstNineDarts = 0

        for turnIndex in turnOrder {
            let darts = turnDarts[turnIndex]!
            let bust = darts.contains { $0.isBust }
            let turnPoints = bust ? 0 : darts.reduce(0) { $0 + $1.dart.points }

            totalScoredPoints += turnPoints
            highestTurn = max(highestTurn, turnPoints)

            if turnPoints == 180 { oneEightys += 1 }
            if turnPoints >= 140 { oneFortyPlus += 1 }
            if turnPoints >= 100 { oneHundredPlus += 1 }

            if turnIndex < 3 {
                firstNinePoints += turnPoints
                firstNineDarts += darts.count
            }
        }

        let threeDartAverage = dartsThrown > 0
            ? Double(totalScoredPoints) / Double(dartsThrown) * 3
            : 0
        let firstNineAverage = firstNineDarts > 0
            ? Double(firstNinePoints) / Double(firstNineDarts) * 3
            : 0

        return MatchStatistics(
            playerIndex: playerIndex,
            dartsThrown: dartsThrown,
            totalScoredPoints: totalScoredPoints,
            threeDartAverage: threeDartAverage,
            firstNineAverage: firstNineAverage,
            checkoutAttempts: checkoutAttempts,
            checkoutHits: checkoutHits,
            checkoutPercentage: checkoutPercentage,
            highestTurn: highestTurn,
            oneHundredPlus: oneHundredPlus,
            oneFortyPlus: oneFortyPlus,
            oneEightys: oneEightys
        )
    }
}
