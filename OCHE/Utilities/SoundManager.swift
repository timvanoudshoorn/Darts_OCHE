import AVFoundation

/// Plays short scoring sound effects, gated by the user's sound setting.
/// Looks for bundled audio files named below; if a file isn't present yet,
/// playback is silently skipped so the app never crashes on missing assets.
final class SoundManager {
    static let shared = SoundManager()

    var isEnabled = true

    private var players: [SoundEffect: AVAudioPlayer] = [:]

    enum SoundEffect: String {
        case dartHit = "dart_hit"
        case doubleHit = "double_hit"
        case tripleHit = "triple_hit"
        case bullHit = "bull_hit"
        case bust = "bust"
        case checkout = "checkout"
        case turnAdvance = "turn_advance"
        case buttonTap = "button_tap"
    }

    private init() {
        for effect in [SoundEffect.dartHit, .doubleHit, .tripleHit, .bullHit, .bust, .checkout, .turnAdvance, .buttonTap] {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf")
                ?? Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else { continue }
            players[effect] = try? AVAudioPlayer(contentsOf: url)
            players[effect]?.prepareToPlay()
        }
    }

    func play(_ effect: SoundEffect) {
        guard isEnabled, let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }
}
