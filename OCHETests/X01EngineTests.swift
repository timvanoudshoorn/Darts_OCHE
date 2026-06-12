import XCTest
@testable import OCHE

final class X01EngineTests: XCTestCase {

    private func players(_ names: String...) -> [GamePlayer] {
        names.map { GamePlayer(name: $0) }
    }

    func testBustRevertsEntireTurnAndUndoRestoresStepByStep() {
        let engine = X01Engine(players: players("A", "B"), startingScore: 100)

        XCTAssertEqual(engine.throwDart(Dart(value: 20, multiplier: .triple)), .normal) // 100-60=40
        XCTAssertEqual(engine.remaining(for: 0), 40)

        XCTAssertEqual(engine.throwDart(Dart(value: 10, multiplier: .single)), .normal) // 40-10=30
        XCTAssertEqual(engine.remaining(for: 0), 30)

        // Overshoot busts the whole turn, reverting to 100.
        XCTAssertEqual(engine.throwDart(Dart(value: 20, multiplier: .triple)), .bust)
        XCTAssertEqual(engine.remaining(for: 0), 100)
        XCTAssertEqual(engine.currentPlayerIndex, 1)

        // Undo the bust: back to 30, still player 0's turn with 2 darts thrown.
        XCTAssertTrue(engine.undo())
        XCTAssertEqual(engine.currentPlayerIndex, 0)
        XCTAssertEqual(engine.remaining(for: 0), 30)
        XCTAssertEqual(engine.currentTurnDarts.count, 2)

        // Undo again: back to 40 with 1 dart thrown.
        XCTAssertTrue(engine.undo())
        XCTAssertEqual(engine.remaining(for: 0), 40)
        XCTAssertEqual(engine.currentTurnDarts.count, 1)

        // Undo again: back to the very start.
        XCTAssertTrue(engine.undo())
        XCTAssertEqual(engine.remaining(for: 0), 100)
        XCTAssertEqual(engine.currentTurnDarts.count, 0)
        XCTAssertFalse(engine.canUndo)
    }

    func testRealBustRevertsToTurnStart() {
        let engine = X01Engine(players: players("A", "B"), startingScore: 41)

        // 41 - 20 = 21 (ok), then 21 - 20 = 1 -> bust (can't leave 1), turn reverts to 41.
        XCTAssertEqual(engine.throwDart(Dart(value: 20, multiplier: .single)), .normal)
        XCTAssertEqual(engine.remaining(for: 0), 21)

        XCTAssertEqual(engine.throwDart(Dart(value: 20, multiplier: .single)), .bust)
        XCTAssertEqual(engine.remaining(for: 0), 41, "Bust must revert the whole turn, not just the busting dart")
        XCTAssertEqual(engine.currentPlayerIndex, 1, "Turn passes to next player after a bust")

        // Undo should restore player 0's turn-in-progress state exactly.
        XCTAssertTrue(engine.undo())
        XCTAssertEqual(engine.currentPlayerIndex, 0)
        XCTAssertEqual(engine.remaining(for: 0), 21)
        XCTAssertEqual(engine.currentTurnDarts.count, 1)
    }

    func testCheckoutEndsGame() {
        let engine = X01Engine(players: players("A", "B"), startingScore: 40)

        XCTAssertEqual(engine.throwDart(Dart(value: 20, multiplier: .double)), .checkout)
        XCTAssertTrue(engine.isGameOver)
        XCTAssertEqual(engine.winnerIndex, 0)
        XCTAssertEqual(engine.remaining(for: 0), 0)
    }

    func testCannotFinishOnOne() {
        let engine = X01Engine(players: players("A"), startingScore: 2)

        // 2 - 1 = 1 -> bust, reverts to 2.
        XCTAssertEqual(engine.throwDart(Dart(value: 1, multiplier: .single)), .bust)
        XCTAssertEqual(engine.remaining(for: 0), 2)
    }

    func testUndoIsMultiStepAcrossManyDarts() {
        let engine = X01Engine(players: players("A"), startingScore: 501)

        for _ in 0..<9 {
            _ = engine.throwDart(Dart(value: 5, multiplier: .single)) // -5 each dart
        }
        XCTAssertEqual(engine.remaining(for: 0), 501 - 45)

        for _ in 0..<9 {
            XCTAssertTrue(engine.undo())
        }
        XCTAssertEqual(engine.remaining(for: 0), 501)
        XCTAssertFalse(engine.canUndo)
    }
}
