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
    }
}
