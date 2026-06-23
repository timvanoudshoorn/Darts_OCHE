import Foundation

/// Computes standard double-out checkout suggestions for remaining scores 2...170.
///
/// Algorithm (documented so it can be unit tested against known reference values):
/// 1. Reject scores outside 2...170, the bogey numbers (169, 168, 166, 165, 163, 162, 159),
///    and 1 — none of these can be finished under double-out rules.
/// 2. Try a 1-dart finish: the remaining score must itself be a valid double
///    (2, 4, ... 40, or 50 for Double Bull).
/// 3. Try a 2-dart finish: for each "setup" dart (descending by points, triples
///    before doubles before singles before bull on point ties — the order a
///    player would naturally reach for), check whether the leftover is a valid
///    double.
/// 4. Try a 3-dart finish the same way, nesting a second setup dart.
///
/// This always returns the *minimum* number of darts required, which matches how
/// the standard checkout chart is conventionally presented (e.g. 100 = T20, D20;
/// 170 = T20, T20, Bull).
enum CheckoutTable {

    /// A single suggested dart in a checkout sequence.
    struct Suggestion: Equatable, Hashable {
        let labels: [String]
        var dartCount: Int { labels.count }
    }

    private static let bogeyNumbers: Set<Int> = [159, 162, 163, 165, 166, 168, 169]

    /// All non-final ("setup") darts, ordered by descending point value with
    /// triple > double > single > bull on ties.
    private static let setupDarts: [(points: Int, label: String)] = {
        var darts: [(Int, String)] = []
        for n in (1...20).reversed() {
            darts.append((n * 3, "T\(n)"))
        }
        darts.append((50, "D Bull"))
        for n in (1...20).reversed() {
            darts.append((n * 2, "D\(n)"))
        }
        darts.append((25, "Bull"))
        for n in (1...20).reversed() {
            darts.append((n, "S\(n)"))
        }
        return darts.sorted { $0.0 > $1.0 }
    }()

    /// All valid finishing doubles, ordered by descending point value.
    private static let finishDarts: [(points: Int, label: String)] = {
        var darts: [(Int, String)] = [(50, "D Bull")]
        for n in (1...20).reversed() {
            darts.append((n * 2, "D\(n)"))
        }
        return darts.sorted { $0.0 > $1.0 }
    }()

    /// Returns the single best (minimum-dart, most natural) checkout suggestion
    /// for `remaining`, or `nil` if no double-out finish exists within 3 darts.
    /// Equivalent to `suggestions(for: remaining, limit: 1).first`.
    static func suggestion(for remaining: Int) -> Suggestion? {
        suggestions(for: remaining, limit: 1).first
    }

    /// Returns up to `limit` distinct checkout suggestions for `remaining`, all
    /// using the same minimum dart count (so every alternative shown is an
    /// equally "good" route, never a worse one padded in for variety). Ordered
    /// most-natural first, matching `suggestion(for:)`'s existing choice.
    static func suggestions(for remaining: Int, limit: Int = 3) -> [Suggestion] {
        guard remaining >= 2, remaining <= 170, remaining != 1,
              !bogeyNumbers.contains(remaining) else { return [] }

        // 1 dart — always unique.
        if let finish = finishDarts.first(where: { $0.points == remaining }) {
            return [Suggestion(labels: [finish.label])]
        }

        // 2 darts
        var twoDart: [Suggestion] = []
        for setup in setupDarts {
            let rest = remaining - setup.points
            guard rest > 0 else { continue }
            if let finish = finishDarts.first(where: { $0.points == rest }) {
                twoDart.append(Suggestion(labels: [setup.label, finish.label]))
                if twoDart.count == limit { break }
            }
        }
        if !twoDart.isEmpty { return twoDart }

        // 3 darts
        var threeDart: [Suggestion] = []
        outer: for first in setupDarts {
            let afterFirst = remaining - first.points
            guard afterFirst > 0 else { continue }
            for second in setupDarts {
                let rest = afterFirst - second.points
                guard rest > 0 else { continue }
                if let finish = finishDarts.first(where: { $0.points == rest }) {
                    threeDart.append(Suggestion(labels: [first.label, second.label, finish.label]))
                    if threeDart.count == limit { break outer }
                }
            }
        }
        return threeDart
    }

    /// Convenience: whether `remaining` can be finished at all (used to drive the
    /// "checkout range" UI highlighting).
    static func isCheckoutPossible(_ remaining: Int) -> Bool {
        suggestion(for: remaining) != nil
    }
}
