import SwiftUI

/// Builds the right engine + game view for a `Route.play(mode, config)`.
struct GameRouterView: View {
    let mode: GameMode
    let config: GameLaunchConfig

    var body: some View {
        switch mode {
        case .standard:
            X01GameView(config: config, engine: X01Engine(players: config.players, startingScore: config.startingScore))
        case .aroundTheClock:
            AroundClockGameView(config: config, engine: AroundClockEngine(
                players: config.players,
                finishOnBull: config.finishOnBull,
                multipliersCount: config.multipliersCount,
                reverse: config.reverse
            ))
        case .cricket:
            CricketGameView(config: config, engine: CricketEngine(players: config.players))
        case .countUp:
            CountUpGameView(config: config, engine: CountUpEngine(players: config.players, totalRounds: config.totalRounds))
        case .killer:
            KillerGameView(config: config, engine: KillerEngine(players: config.players, startingLives: config.startingLives))
        case .shanghai:
            ShanghaiGameView(config: config, engine: ShanghaiEngine(players: config.players, totalRounds: config.totalRounds))
        case .halveIt:
            HalveItGameView(config: config, engine: HalveItEngine(players: config.players))
        case .practice170:
            Practice170GameView(config: config, engine: Practice170Engine(players: config.players))
        }
    }
}
