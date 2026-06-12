import Foundation
import SwiftUI

/// Navigation destinations for the single root `NavigationStack`.
enum Route: Hashable, Codable {
    case setup(GameMode)
    case play(GameMode, GameLaunchConfig)
}

/// Owns the navigation path so any screen (in particular `GameOverView`) can
/// jump back to Home or replace itself with a fresh match without threading
/// bindings through every game view.
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func popToRoot() {
        path = NavigationPath()
    }

    /// Pops the current "play" destination and pushes a fresh one with the
    /// same configuration — used by "Play Again" to get a brand-new engine
    /// instance (and thus a clean `@StateObject`/state history).
    func restart(mode: GameMode, config: GameLaunchConfig) {
        if !path.isEmpty { path.removeLast() }
        path.append(Route.play(mode, config))
    }
}
