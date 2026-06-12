import Foundation

/// All the configuration a `SetupView` can collect, regardless of mode.
/// The relevant subset is read by `GameRouterView` to build the engine for
/// the chosen `GameMode`.
struct GameLaunchConfig: Hashable, Codable {
    var players: [GamePlayer] = []

    // Standard Darts
    var startingScore: Int = 501

    // Around the Clock
    var finishOnBull: Bool = false
    var multipliersCount: Bool = false
    var reverse: Bool = false

    // Count-Up / Shanghai
    var totalRounds: Int = 7

    // Killer
    var startingLives: Int = 3
}
