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
/// - `highestCheckout` is the highest single-turn point total among turns
///   that contain a dart with `isCheckoutHit == true`. `bestLegDarts` is the
///   fewest darts thrown between two checkouts (or from game start to the
///   first checkout), counting busted darts too since they were still
///   thrown during that leg attempt. Both are only meaningful for modes with
///   a real double-out checkout (X01, Practice170, Around the Clock) —
///   Cricket and Halve-It never set `isCheckoutHit`, so they correctly read
///   `0`/`nil` rather than being a bug to "fix" later.
struct MatchStatistics: Equatable, Codable {
    var playerIndex: Int
    var dartsThrown: Int
    var totalScoredPoints: Int
    var threeDartAverage: Double
    var firstNineAverage: Double
    var firstNinePoints: Int
    var firstNineDarts: Int
    var checkoutAttempts: Int
    var checkoutHits: Int
    var checkoutPercentage: Double
    var highestTurn: Int
    var highestCheckout: Int
    var bestLegDarts: Int?
    var oneHundredPlus: Int
    var oneFortyPlus: Int
    var oneEightys: Int

    private enum CodingKeys: String, CodingKey {
        case playerIndex, dartsThrown, totalScoredPoints, threeDartAverage, firstNineAverage
        case firstNinePoints, firstNineDarts
        case checkoutAttempts, checkoutHits, checkoutPercentage
        case highestTurn, highestCheckout, bestLegDarts
        case oneHundredPlus, oneFortyPlus, oneEightys
    }

    /// Custom decoding so match history saved *before* `firstNinePoints`,
    /// `firstNineDarts`, `highestCheckout`, and `bestLegDarts` existed still
    /// decodes cleanly — `Persistence.swift` falls back to an empty array on
    /// any decode failure, which would otherwise silently wipe old stats
    /// from view instead of just missing these 4 new fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        playerIndex = try c.decode(Int.self, forKey: .playerIndex)
        dartsThrown = try c.decode(Int.self, forKey: .dartsThrown)
        totalScoredPoints = try c.decode(Int.self, forKey: .totalScoredPoints)
        threeDartAverage = try c.decode(Double.self, forKey: .threeDartAverage)
        firstNineAverage = try c.decode(Double.self, forKey: .firstNineAverage)
        firstNinePoints = try c.decodeIfPresent(Int.self, forKey: .firstNinePoints) ?? 0
        firstNineDarts = try c.decodeIfPresent(Int.self, forKey: .firstNineDarts) ?? 0
        checkoutAttempts = try c.decode(Int.self, forKey: .checkoutAttempts)
        checkoutHits = try c.decode(Int.self, forKey: .checkoutHits)
        checkoutPercentage = try c.decode(Double.self, forKey: .checkoutPercentage)
        highestTurn = try c.decode(Int.self, forKey: .highestTurn)
        highestCheckout = try c.decodeIfPresent(Int.self, forKey: .highestCheckout) ?? 0
        bestLegDarts = try c.decodeIfPresent(Int.self, forKey: .bestLegDarts) ?? nil
        oneHundredPlus = try c.decode(Int.self, forKey: .oneHundredPlus)
        oneFortyPlus = try c.decode(Int.self, forKey: .oneFortyPlus)
        oneEightys = try c.decode(Int.self, forKey: .oneEightys)
    }

    init(
        playerIndex: Int, dartsThrown: Int, totalScoredPoints: Int,
        threeDartAverage: Double, firstNineAverage: Double,
        firstNinePoints: Int, firstNineDarts: Int,
        checkoutAttempts: Int, checkoutHits: Int, checkoutPercentage: Double,
        highestTurn: Int, highestCheckout: Int, bestLegDarts: Int?,
        oneHundredPlus: Int, oneFortyPlus: Int, oneEightys: Int
    ) {
        self.playerIndex = playerIndex
        self.dartsThrown = dartsThrown
        self.totalScoredPoints = totalScoredPoints
        self.threeDartAverage = threeDartAverage
        self.firstNineAverage = firstNineAverage
        self.firstNinePoints = firstNinePoints
        self.firstNineDarts = firstNineDarts
        self.checkoutAttempts = checkoutAttempts
        self.checkoutHits = checkoutHits
        self.checkoutPercentage = checkoutPercentage
        self.highestTurn = highestTurn
        self.highestCheckout = highestCheckout
        self.bestLegDarts = bestLegDarts
        self.oneHundredPlus = oneHundredPlus
        self.oneFortyPlus = oneFortyPlus
        self.oneEightys = oneEightys
    }

    static func compute(from dartLog: [DartLogEntry], playerIndex: Int) -> MatchStatistics {
        let entries = dartLog.filter { $0.playerIndex == playerIndex }

        let dartsThrown = entries.count
        let checkoutAttempts = entries.filter { $0.isCheckoutAttempt }.count
        let checkoutHits = entries.filter { $0.isCheckoutHit }.count
        let checkoutPercentage = checkoutAttempts > 0
            ? Double(checkoutHits) / Double(checkoutAttempts) * 100
            : 0

        let turns = dartLog.groupedByTurn(playerIndex: playerIndex)

        var totalScoredPoints = 0
        var highestTurn = 0
        var highestCheckout = 0
        var oneHundredPlus = 0
        var oneFortyPlus = 0
        var oneEightys = 0
        var firstNinePoints = 0
        var firstNineDarts = 0

        for (turnIndex, darts) in turns {
            let bust = darts.contains { $0.isBust }
            let turnPoints = bust ? 0 : darts.reduce(0) { $0 + $1.dart.points }

            totalScoredPoints += turnPoints
            highestTurn = max(highestTurn, turnPoints)

            if darts.contains(where: { $0.isCheckoutHit }) {
                highestCheckout = max(highestCheckout, turnPoints)
            }

            if turnPoints == 180 { oneEightys += 1 }
            if turnPoints >= 140 { oneFortyPlus += 1 }
            if turnPoints >= 100 { oneHundredPlus += 1 }

            if turnIndex < 3 {
                firstNinePoints += turnPoints
                firstNineDarts += darts.count
            }
        }

        // Fewest darts thrown in any single completed leg (from game start or
        // the previous checkout, through and including the checkout dart) —
        // busted darts still count, they were still thrown during that leg.
        var bestLegDarts: Int? = nil
        var dartsSinceLastCheckout = 0
        for entry in entries {
            dartsSinceLastCheckout += 1
            if entry.isCheckoutHit {
                bestLegDarts = bestLegDarts.map { min($0, dartsSinceLastCheckout) } ?? dartsSinceLastCheckout
                dartsSinceLastCheckout = 0
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
            firstNinePoints: firstNinePoints,
            firstNineDarts: firstNineDarts,
            checkoutAttempts: checkoutAttempts,
            checkoutHits: checkoutHits,
            checkoutPercentage: checkoutPercentage,
            highestTurn: highestTurn,
            highestCheckout: highestCheckout,
            bestLegDarts: bestLegDarts,
            oneHundredPlus: oneHundredPlus,
            oneFortyPlus: oneFortyPlus,
            oneEightys: oneEightys
        )
    }
}
