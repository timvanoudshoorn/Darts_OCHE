import UIKit

/// Thin wrapper around `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`,
/// gated by the user's haptics setting.
final class HapticManager {
    static let shared = HapticManager()

    var isEnabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {}

    func dartThrown() {
        guard isEnabled else { return }
        light.impactOccurred()
    }

    func bigHit() {
        guard isEnabled else { return }
        medium.impactOccurred()
    }

    func checkout() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func bust() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    func turnAdvance() {
        guard isEnabled else { return }
        heavy.impactOccurred(intensity: 0.6)
    }
}
