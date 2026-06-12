import XCTest
@testable import OCHE

final class CheckoutTableTests: XCTestCase {

    func testClassicTonPlusFinishes() {
        XCTAssertEqual(CheckoutTable.suggestion(for: 170)?.labels, ["T20", "T20", "D Bull"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 167)?.labels, ["T20", "T19", "D Bull"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 164)?.labels, ["T20", "T18", "D Bull"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 161)?.labels, ["T20", "T17", "D Bull"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 158)?.labels, ["T20", "T20", "D19"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 100)?.labels, ["T20", "D20"])
    }

    func testOneDartFinishes() {
        XCTAssertEqual(CheckoutTable.suggestion(for: 50)?.labels, ["D Bull"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 40)?.labels, ["D20"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 32)?.labels, ["D16"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 2)?.labels, ["D1"])
    }

    func testTwoAndThreeDartFinishes() {
        XCTAssertEqual(CheckoutTable.suggestion(for: 3)?.labels, ["S1", "D1"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 36)?.labels, ["D18"])
        XCTAssertEqual(CheckoutTable.suggestion(for: 60)?.labels, ["T18", "D3"])
    }

    func testBogeyNumbersHaveNoFinish() {
        for bogey in [159, 162, 163, 165, 166, 168, 169] {
            XCTAssertNil(CheckoutTable.suggestion(for: bogey), "\(bogey) should have no double-out finish")
        }
    }

    func testImpossibleScoresHaveNoFinish() {
        XCTAssertNil(CheckoutTable.suggestion(for: 1))
        XCTAssertNil(CheckoutTable.suggestion(for: 0))
        XCTAssertNil(CheckoutTable.suggestion(for: 171))
    }

    func testEverySuggestionEndsInAValidDoubleAndSumsCorrectly() {
        let dartValues: [String: Int] = makeDartPointMap()

        for remaining in 2...170 {
            guard let suggestion = CheckoutTable.suggestion(for: remaining) else { continue }
            XCTAssertTrue(suggestion.labels.count <= 3, "\(remaining) used more than 3 darts")

            let last = suggestion.labels.last!
            XCTAssertTrue(last == "D Bull" || last.hasPrefix("D"), "\(remaining) must finish on a double, got \(last)")

            let total = suggestion.labels.reduce(0) { $0 + (dartValues[$1] ?? 0) }
            XCTAssertEqual(total, remaining, "\(remaining): \(suggestion.labels) sums to \(total)")
        }
    }

    private func makeDartPointMap() -> [String: Int] {
        var map: [String: Int] = ["D Bull": 50, "Bull": 25]
        for n in 1...20 {
            map["S\(n)"] = n
            map["D\(n)"] = n * 2
            map["T\(n)"] = n * 3
        }
        return map
    }
}
