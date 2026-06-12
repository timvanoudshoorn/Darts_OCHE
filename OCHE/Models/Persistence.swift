import Foundation
import SwiftData

/// A local player profile. No account required — purely on-device. Lifetime
/// aggregates are updated incrementally when a `MatchRecord` is saved.
@Model
final class PlayerProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    var totalMatchesPlayed: Int = 0
    var totalMatchesWon: Int = 0
    var totalDartsThrown: Int = 0
    var totalPointsScored: Int = 0
    var total180s: Int = 0
    var total140Plus: Int = 0
    var total100Plus: Int = 0
    var bestThreeDartAverage: Double = 0
    var bestCheckoutPoints: Int = 0

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }

    /// Folds a completed match's stats into this profile's lifetime aggregates.
    func record(stats: MatchStatistics, won: Bool, finishedPoints: Int?) {
        totalMatchesPlayed += 1
        if won { totalMatchesWon += 1 }
        totalDartsThrown += stats.dartsThrown
        totalPointsScored += stats.totalScoredPoints
        total180s += stats.oneEightys
        total140Plus += stats.oneFortyPlus
        total100Plus += stats.oneHundredPlus
        bestThreeDartAverage = max(bestThreeDartAverage, stats.threeDartAverage)
        if let finishedPoints {
            bestCheckoutPoints = max(bestCheckoutPoints, finishedPoints)
        }
    }

    /// Lifetime 3-dart average across all recorded matches.
    var lifetimeThreeDartAverage: Double {
        totalDartsThrown > 0 ? Double(totalPointsScored) / Double(totalDartsThrown) * 3 : 0
    }
}

/// A completed match, stored for the history/charts screen.
@Model
final class MatchRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var modeRaw: String
    var playerNames: [String]
    var winnerIndex: Int?
    private var statsData: Data

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .standard }

    var stats: [MatchStatistics] {
        (try? JSONDecoder().decode([MatchStatistics].self, from: statsData)) ?? []
    }

    init(mode: GameMode, playerNames: [String], winnerIndex: Int?, stats: [MatchStatistics]) {
        self.id = UUID()
        self.date = Date()
        self.modeRaw = mode.rawValue
        self.playerNames = playerNames
        self.winnerIndex = winnerIndex
        self.statsData = (try? JSONEncoder().encode(stats)) ?? Data()
    }
}
