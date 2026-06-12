import SwiftUI
import Combine

/// User-configurable feedback toggles, persisted to `UserDefaults` and applied
/// instantly. Shown in the bottom-sheet Settings panel.
final class SettingsStore: ObservableObject {
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    @Published var particlesEnabled: Bool {
        didSet { defaults.set(particlesEnabled, forKey: Keys.particles) }
    }
    @Published var popupsEnabled: Bool {
        didSet { defaults.set(popupsEnabled, forKey: Keys.popups) }
    }
    @Published var flashEnabled: Bool {
        didSet { defaults.set(flashEnabled, forKey: Keys.flash) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let sound = "settings.soundEnabled"
        static let haptics = "settings.hapticsEnabled"
        static let particles = "settings.particlesEnabled"
        static let popups = "settings.popupsEnabled"
        static let flash = "settings.flashEnabled"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        particlesEnabled = defaults.object(forKey: Keys.particles) as? Bool ?? true
        popupsEnabled = defaults.object(forKey: Keys.popups) as? Bool ?? true
        flashEnabled = defaults.object(forKey: Keys.flash) as? Bool ?? true
    }
}
