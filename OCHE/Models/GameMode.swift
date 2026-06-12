import SwiftUI

/// All supported game modes, each with its own accent color and home-screen presentation.
enum GameMode: String, CaseIterable, Identifiable, Codable {
    case aroundTheClock
    case standard
    case cricket
    case countUp
    case killer
    case shanghai
    case halveIt
    case practice170

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aroundTheClock: return "Around the Clock"
        case .standard: return "Standard Darts"
        case .cricket: return "Cricket"
        case .countUp: return "Count-Up"
        case .killer: return "Killer"
        case .shanghai: return "Shanghai"
        case .halveIt: return "Halve-It"
        case .practice170: return "170 Practice"
        }
    }

    var subtitle: String {
        switch self {
        case .aroundTheClock: return "Race from 1 to 20 (+ Bull)"
        case .standard: return "301 / 501 · Double-out"
        case .cricket: return "15-20 + Bull, close & score"
        case .countUp: return "Highest score over N rounds"
        case .killer: return "Last player standing"
        case .shanghai: return "Single, double, triple — instant win"
        case .halveIt: return "Hit the target or lose half"
        case .practice170: return "WDA team checkout drill"
        }
    }

    var accentColor: Color {
        switch self {
        case .aroundTheClock: return Theme.modeAroundClock
        case .standard: return Theme.modeStandard
        case .cricket: return Theme.modeCricket
        case .countUp: return Theme.modeCountUp
        case .killer: return Theme.modeKiller
        case .shanghai: return Theme.modeShanghai
        case .halveIt: return Theme.modeHalveIt
        case .practice170: return Theme.modePractice170
        }
    }

    var icon: String {
        switch self {
        case .aroundTheClock: return "clock.fill"
        case .standard: return "target"
        case .cricket: return "ladybug.fill"
        case .countUp: return "arrow.up.right.circle.fill"
        case .killer: return "bolt.heart.fill"
        case .shanghai: return "tram.fill"
        case .halveIt: return "divide.circle.fill"
        case .practice170: return "graduationcap.fill"
        }
    }

    /// Minimum / maximum number of players supported by this mode.
    var playerRange: ClosedRange<Int> {
        switch self {
        case .killer: return 2...8
        case .practice170: return 1...8
        default: return 1...8
        }
    }
}
