import SwiftUI

/// A player participating in a match. Lightweight value type — persisted stats
/// live in `PlayerProfile` (SwiftData) and are looked up via `profileID`.
struct GamePlayer: Codable, Equatable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var profileID: UUID? = nil
}

/// One dart thrown during a match, tagged with who threw it and when.
/// Engines append to a `dartLog` inside their `State` so that undo (which
/// restores the whole state) automatically restores the log too, and so the
/// stats engine can recompute everything from scratch at any point.
struct DartLogEntry: Codable, Equatable {
    var playerIndex: Int
    var turnIndex: Int
    var dart: Dart
    /// True if this dart busted the turn (mode-specific meaning, e.g. x01 overshoot).
    var isBust: Bool = false
    /// True if this dart was thrown while the player's remaining score was a
    /// possible checkout (≤170 and a valid double-out exists) — used for
    /// checkout percentage.
    var isCheckoutAttempt: Bool = false
    /// True if this dart resulted in the player finishing (winning the leg).
    var isCheckoutHit: Bool = false
}

extension Array where Element == DartLogEntry {
    /// Groups one player's entries into turns, preserving encounter order —
    /// the same grouping `MatchStatistics.compute` uses, shared so a match's
    /// computed stats and its turn-by-turn history view can never disagree
    /// about where turn boundaries fall.
    func groupedByTurn(playerIndex: Int) -> [(turnIndex: Int, darts: [DartLogEntry])] {
        let entries = filter { $0.playerIndex == playerIndex }
        var turnOrder: [Int] = []
        var turnDarts: [Int: [DartLogEntry]] = [:]
        for entry in entries {
            if turnDarts[entry.turnIndex] == nil {
                turnDarts[entry.turnIndex] = []
                turnOrder.append(entry.turnIndex)
            }
            turnDarts[entry.turnIndex]!.append(entry)
        }
        return turnOrder.map { ($0, turnDarts[$0]!) }
    }
}

/// Drives the center-screen popup ("OUT ✓", "Triple 20 / 60 pts", "Busted!", "Halved!"...).
/// Popups are purely informational/non-blocking — the UI auto-dismisses them and the
/// player can keep tapping immediately.
struct PopupEvent: Identifiable, Equatable {
    enum Kind: Equatable {
        case info
        case success
        case checkout
        case bust
        case halved
        case danger
    }

    let id = UUID()
    var title: String
    var subtitle: String? = nil
    var icon: String
    var kind: Kind
    var color: Color

    static func dartHit(_ dart: Dart, accent: Color) -> PopupEvent {
        switch (dart.value, dart.multiplier) {
        case (25, .double):
            return PopupEvent(title: "Double Bull", subtitle: "50 points", icon: "scope", kind: .success, color: Theme.double)
        case (25, _):
            return PopupEvent(title: "Bull", subtitle: "25 points", icon: "scope", kind: .info, color: Theme.single)
        case (_, .triple):
            return PopupEvent(title: "Triple \(dart.value)", subtitle: "\(dart.points) pts", icon: "burst.fill", kind: .success, color: Theme.triple)
        case (_, .double):
            return PopupEvent(title: "Double \(dart.value)", subtitle: "\(dart.points) pts", icon: "burst.fill", kind: .success, color: Theme.double)
        default:
            return PopupEvent(title: "\(dart.points) pts", subtitle: nil, icon: "circle.fill", kind: .info, color: accent)
        }
    }

    static func checkout(remaining: Int = 0) -> PopupEvent {
        PopupEvent(title: "OUT ✓", subtitle: "Checkout!", icon: "checkmark.seal.fill", kind: .checkout, color: Theme.scoreCheckout)
    }

    static func bust() -> PopupEvent {
        PopupEvent(title: "Busted!", subtitle: "Score reverts to start of turn", icon: "xmark.octagon.fill", kind: .bust, color: Theme.bust)
    }

    static func halved(newScore: Int) -> PopupEvent {
        PopupEvent(title: "Halved!", subtitle: "Score now \(newScore)", icon: "divide.circle.fill", kind: .halved, color: Theme.modeHalveIt)
    }

    static func turnDone(next playerName: String) -> PopupEvent {
        PopupEvent(title: "Turn Done", subtitle: "Next: \(playerName)", icon: "arrow.right.circle.fill", kind: .info, color: Theme.glowSky)
    }

    static func gameOver(winner: String) -> PopupEvent {
        PopupEvent(title: "Game Over", subtitle: "\(winner) wins!", icon: "trophy.fill", kind: .checkout, color: Theme.scoreCheckout)
    }
}

/// Base class providing a generic, per-mutation snapshot stack so every engine
/// gets robust multi-step undo "for free": each call to `mutate` pushes a full
/// copy of the previous state before applying the change, and `undo()` restores
/// it exactly — including every score, log entry, and stat-affecting field.
///
/// `State` must be a value type (struct) conforming to `Codable & Equatable` so
/// snapshots are cheap, independent copies.
class GameEngineBase<State: Codable & Equatable>: ObservableObject {
    @Published private(set) var state: State
    @Published private(set) var canUndo: Bool = false

    /// Snapshot taken before every dart/mutation. Capped to avoid unbounded growth.
    private var history: [State] = []
    private let maxHistory = 400

    init(initialState: State) {
        self.state = initialState
    }

    /// Apply a mutation to the state, automatically snapshotting the prior
    /// state first so it can be perfectly restored via `undo()`.
    func mutate(_ block: (inout State) -> Void) {
        history.append(state)
        if history.count > maxHistory { history.removeFirst() }
        var newState = state
        block(&newState)
        state = newState
        canUndo = !history.isEmpty
    }

    /// Restore the state to exactly how it was before the last `mutate` call.
    /// Returns `false` if there is nothing to undo.
    @discardableResult
    func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        state = previous
        canUndo = !history.isEmpty
        return true
    }

    /// Read-only access for views; subclasses expose typed computed properties
    /// on top of this.
    var current: State { state }

    func resetHistory() {
        history.removeAll()
        canUndo = false
    }
}
