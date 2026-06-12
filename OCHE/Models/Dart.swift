import SwiftUI

/// The multiplier applied to a dart's base segment value.
enum Multiplier: Int, Codable, CaseIterable, Identifiable, Hashable {
    case single = 1
    case double = 2
    case triple = 3

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .single: return "S"
        case .double: return "D"
        case .triple: return "T"
        }
    }

    var fullName: String {
        switch self {
        case .single: return "Single"
        case .double: return "Double"
        case .triple: return "Triple"
        }
    }

    var color: Color { Theme.color(for: self) }
}

/// A single dart throw: a board segment (1-20, or 25 for bull) and a multiplier.
/// `value == 0` represents a miss (scores 0 regardless of multiplier).
/// Bull (`value == 25`) only supports `.single` (25) and `.double` (50) — triple bull
/// does not exist on a standard board and is rejected by `points`.
struct Dart: Codable, Equatable, Hashable, Identifiable {
    var id = UUID()
    var value: Int       // 0 = miss, 1...20 = numbers, 25 = bull
    var multiplier: Multiplier

    init(value: Int, multiplier: Multiplier = .single) {
        self.value = value
        self.multiplier = (value == 25 && multiplier == .triple) ? .double : multiplier
    }

    /// A throw that misses the board entirely.
    static let miss = Dart(value: 0, multiplier: .single)

    /// Points scored by this dart.
    var points: Int {
        if value == 0 { return 0 }
        if value == 25 {
            return multiplier == .double ? 50 : 25
        }
        return value * multiplier.rawValue
    }

    var isBull: Bool { value == 25 }
    var isMiss: Bool { value == 0 }
    var isDouble: Bool { multiplier == .double && value != 0 }

    /// Short scoreboard label, e.g. "T20", "D Bull", "25", "Miss".
    var label: String {
        if value == 0 { return "Miss" }
        if value == 25 {
            return multiplier == .double ? "D Bull" : "Bull"
        }
        return "\(multiplier.shortLabel)\(value)"
    }

    /// Long popup label, e.g. "Triple 20", "Double Bull".
    var fullLabel: String {
        if value == 0 { return "Miss" }
        if value == 25 {
            return multiplier == .double ? "Double Bull" : "Bull"
        }
        return "\(multiplier.fullName) \(value)"
    }
}

extension Array where Element == Dart {
    /// Total points for a turn (array of up to 3 darts).
    var totalPoints: Int { reduce(0) { $0 + $1.points } }
}
