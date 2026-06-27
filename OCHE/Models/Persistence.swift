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
    var totalCheckoutAttempts: Int = 0
    var totalCheckoutHits: Int = 0
    var totalFirstNinePoints: Int = 0
    var totalFirstNineDarts: Int = 0
    /// Fewest darts ever used to complete a leg. `0` means "no record yet" —
    /// real values are always >= 1.
    var bestLegDarts: Int = 0

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }

    /// Folds a completed match's stats into this profile's lifetime aggregates.
    func record(stats: MatchStatistics, won: Bool) {
        totalMatchesPlayed += 1
        if won { totalMatchesWon += 1 }
        totalDartsThrown += stats.dartsThrown
        totalPointsScored += stats.totalScoredPoints
        total180s += stats.oneEightys
        total140Plus += stats.oneFortyPlus
        total100Plus += stats.oneHundredPlus
        bestThreeDartAverage = max(bestThreeDartAverage, stats.threeDartAverage)
        bestCheckoutPoints = max(bestCheckoutPoints, stats.highestCheckout)
        totalCheckoutAttempts += stats.checkoutAttempts
        totalCheckoutHits += stats.checkoutHits
        totalFirstNinePoints += stats.firstNinePoints
        totalFirstNineDarts += stats.firstNineDarts
        if let legDarts = stats.bestLegDarts {
            bestLegDarts = bestLegDarts == 0 ? legDarts : min(bestLegDarts, legDarts)
        }
    }

    /// Lifetime 3-dart average across all recorded matches.
    var lifetimeThreeDartAverage: Double {
        totalDartsThrown > 0 ? Double(totalPointsScored) / Double(totalDartsThrown) * 3 : 0
    }

    /// Lifetime checkout percentage across all recorded matches.
    var lifetimeCheckoutPercentage: Double {
        totalCheckoutAttempts > 0 ? Double(totalCheckoutHits) / Double(totalCheckoutAttempts) * 100 : 0
    }

    /// Lifetime first-9 average across all recorded matches.
    var lifetimeFirstNineAverage: Double {
        totalFirstNineDarts > 0 ? Double(totalFirstNinePoints) / Double(totalFirstNineDarts) * 3 : 0
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
    /// Full per-dart history for this match, so a detail screen can show a
    /// turn-by-turn breakdown later. Added after `statsData` existed, so
    /// defaults to empty for any match saved before this field existed.
    private var dartLogData: Data = Data()

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .standard }

    var stats: [MatchStatistics] {
        (try? JSONDecoder().decode([MatchStatistics].self, from: statsData)) ?? []
    }

    var dartLog: [DartLogEntry] {
        (try? JSONDecoder().decode([DartLogEntry].self, from: dartLogData)) ?? []
    }

    init(mode: GameMode, playerNames: [String], winnerIndex: Int?, stats: [MatchStatistics], dartLog: [DartLogEntry]) {
        self.id = UUID()
        self.date = Date()
        self.modeRaw = mode.rawValue
        self.playerNames = playerNames
        self.winnerIndex = winnerIndex
        self.statsData = (try? JSONEncoder().encode(stats)) ?? Data()
        self.dartLogData = (try? JSONEncoder().encode(dartLog)) ?? Data()
    }
}
