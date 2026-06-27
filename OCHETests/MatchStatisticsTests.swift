import XCTest
@testable import OCHE

final class MatchStatisticsTests: XCTestCase {

    private func entry(turn: Int, _ value: Int, _ mult: Multiplier, bust: Bool = false,
                        attempt: Bool = false, hit: Bool = false) -> DartLogEntry {
        DartLogEntry(playerIndex: 0, turnIndex: turn, dart: Dart(value: value, multiplier: mult),
                     isBust: bust, isCheckoutAttempt: attempt, isCheckoutHit: hit)
    }

    func testThreeDartAverageAndHighestTurn() {
        // Turn 0: T20, T20, T20 = 180. Turn 1: 20, 20, 20 = 60.
        let log: [DartLogEntry] = [
            entry(turn: 0, 20, .triple),
            entry(turn: 0, 20, .triple),
            entry(turn: 0, 20, .triple),
            entry(turn: 1, 20, .single),
            entry(turn: 1, 20, .single),
            entry(turn: 1, 20, .single),
        ]

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.dartsThrown, 6)
        XCTAssertEqual(stats.totalScoredPoints, 240)
        XCTAssertEqual(stats.threeDartAverage, 120, accuracy: 0.001) // 240/6*3
        XCTAssertEqual(stats.highestTurn, 180)
        XCTAssertEqual(stats.oneEightys, 1)
        XCTAssertEqual(stats.oneFortyPlus, 1)
        XCTAssertEqual(stats.oneHundredPlus, 1)
    }

    func testFirstNineAverageOnlyUsesFirstThreeTurns() {
        // Turns 0-2: 20,20,20 (=60) each -> first 9 darts total 180 -> first-9 avg = 60.
        // Turn 3: a big 180 that must NOT affect the first-9 average.
        var log: [DartLogEntry] = (0...2).flatMap { turn in (0..<3).map { _ in entry(turn: turn, 20, .single) } }
        log += (0..<3).map { _ in entry(turn: 3, 20, .triple) } // 180 in turn 3

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.firstNineAverage, 60, accuracy: 0.001)
        XCTAssertEqual(stats.threeDartAverage, (180 + 180) / 12.0 * 3, accuracy: 0.001)
    }

    func testBustedTurnContributesZeroPoints() {
        let log: [DartLogEntry] = [
            entry(turn: 0, 20, .triple),                 // 60, would-be score
            entry(turn: 0, 20, .triple),                 // 60
            entry(turn: 0, 20, .triple, bust: true),     // busts -> whole turn = 0
        ]

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.totalScoredPoints, 0)
        XCTAssertEqual(stats.highestTurn, 0)
        XCTAssertEqual(stats.oneEightys, 0)
        // Darts are still counted as thrown for averaging purposes.
        XCTAssertEqual(stats.dartsThrown, 3)
        XCTAssertEqual(stats.threeDartAverage, 0)
    }

    func testCheckoutPercentage() {
        let log: [DartLogEntry] = [
            entry(turn: 0, 20, .single, attempt: false),
            entry(turn: 0, 20, .single, attempt: false),
            entry(turn: 0, 20, .single, attempt: false),
            // Now in checkout range: two attempts, one hit.
            entry(turn: 1, 20, .single, attempt: true, hit: false),
            entry(turn: 1, 10, .double, attempt: true, hit: true),
        ]

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.checkoutAttempts, 2)
        XCTAssertEqual(stats.checkoutHits, 1)
        XCTAssertEqual(stats.checkoutPercentage, 50, accuracy: 0.001)
    }

    func testEmptyLogProducesZeroedStats() {
        let stats = MatchStatistics.compute(from: [], playerIndex: 0)
        XCTAssertEqual(stats.dartsThrown, 0)
        XCTAssertEqual(stats.threeDartAverage, 0)
        XCTAssertEqual(stats.firstNineAverage, 0)
        XCTAssertEqual(stats.checkoutPercentage, 0)
        XCTAssertEqual(stats.highestCheckout, 0)
        XCTAssertNil(stats.bestLegDarts)
    }

    func testFirstNinePointsAndDartsAreExposedAsRawCounts() {
        // Same scenario as testFirstNineAverageOnlyUsesFirstThreeTurns, but
        // asserting the raw counts the lifetime rollup depends on, not just
        // the derived per-match average.
        var log: [DartLogEntry] = (0...2).flatMap { turn in (0..<3).map { _ in entry(turn: turn, 20, .single) } }
        log += (0..<3).map { _ in entry(turn: 3, 20, .triple) }

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.firstNinePoints, 180)
        XCTAssertEqual(stats.firstNineDarts, 9)
    }

    func testHighestCheckoutTracksBestOfMultipleCheckoutsInOneMatch() {
        // Leg 1: 20, 20, D20(hit) = 80 across 3 darts.
        // Leg 2 (e.g. a Practice170-style re-checkout in the same match): a
        // single D20(hit) = 40 across just 1 dart.
        let log: [DartLogEntry] = [
            entry(turn: 0, 20, .single),
            entry(turn: 0, 20, .single),
            entry(turn: 0, 20, .double, hit: true),
            entry(turn: 1, 20, .double, hit: true),
        ]

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.highestCheckout, 80)
        XCTAssertEqual(stats.bestLegDarts, 1)
    }

    func testBestLegDartsCountsBustedDartsTowardTheLeg() {
        // A bust costs a dart even though it scores nothing, so the leg that
        // contains it should count that dart toward its total.
        let log: [DartLogEntry] = [
            entry(turn: 0, 20, .triple, bust: true),
            entry(turn: 1, 20, .double, hit: true),
        ]

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.bestLegDarts, 2)
    }

    func testHighestCheckoutAndBestLegDartsStayZeroNilWithoutCheckoutFlags() {
        // Cricket/Halve-It never set isCheckoutHit — confirm that's read as
        // "no checkout this match", not mistaken for a bug.
        let log: [DartLogEntry] = [
            entry(turn: 0, 20, .single),
            entry(turn: 0, 19, .single),
            entry(turn: 0, 18, .single),
        ]

        let stats = MatchStatistics.compute(from: log, playerIndex: 0)

        XCTAssertEqual(stats.highestCheckout, 0)
        XCTAssertNil(stats.bestLegDarts)
    }

    func testDecodingOldMatchRecordJSONWithoutNewFieldsUsesDefaults() {
        // Shape of MatchStatistics JSON as it existed before firstNinePoints,
        // firstNineDarts, highestCheckout, and bestLegDarts were added —
        // decoding this must not throw, or old saved match history would
        // silently disappear (Persistence.swift falls back to `[]` on any
        // decode failure).
        let oldJSON = """
        {
            "playerIndex": 0,
            "dartsThrown": 9,
            "totalScoredPoints": 540,
            "threeDartAverage": 180,
            "firstNineAverage": 180,
            "checkoutAttempts": 0,
            "checkoutHits": 0,
            "checkoutPercentage": 0,
            "highestTurn": 180,
            "oneHundredPlus": 3,
            "oneFortyPlus": 3,
            "oneEightys": 3
        }
        """.data(using: .utf8)!

        let stats = try? JSONDecoder().decode(MatchStatistics.self, from: oldJSON)

        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.highestTurn, 180)
        XCTAssertEqual(stats?.oneEightys, 3)
        XCTAssertEqual(stats?.firstNinePoints, 0)
        XCTAssertEqual(stats?.firstNineDarts, 0)
        XCTAssertEqual(stats?.highestCheckout, 0)
        XCTAssertNil(stats?.bestLegDarts)
    }
}
