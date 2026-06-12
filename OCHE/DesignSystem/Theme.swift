import SwiftUI

/// Central color & style palette for OCHE. Keep in sync with the
/// design language defined in the original prototype.
enum Theme {
    // MARK: Base

    static let background = Color(hex: 0x07050C)
    static let surface = Color(hex: 0x130F1E)
    static let surfaceElevated = Color(hex: 0x1C1530)
    static let stroke = Color.white.opacity(0.08)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    // MARK: Ambient gradient colors (background glows)

    static let glowTeal = Color(hex: 0x00E5A0)
    static let glowSky = Color(hex: 0x7EB8FF)
    static let glowPink = Color(hex: 0xF472B6)
    static let glowViolet = Color(hex: 0xA78BFA)

    // MARK: Multiplier colors (drive number pad re-tint)

    static let single = Color(hex: 0xF5F3F0) // cream / white
    static let double = Color(hex: 0x2ED573) // green
    static let triple = Color(hex: 0xFF4560) // red

    // MARK: Score card thresholds

    static let scoreHigh = Color(hex: 0xF5F3F0)        // > 170
    static let scoreMid = Color(hex: 0x7EB8FF)         // <= 170
    static let scoreLow = Color(hex: 0xFFD166)         // <= 100
    static let scoreCheckout = Color(hex: 0x00E5A0)    // <= 40 "Checkout range!"

    // MARK: Game mode accent colors

    static let modeAroundClock = glowTeal
    static let modeStandard = glowSky
    static let modeCricket = Color(hex: 0xFF6B6B)
    static let modeCountUp = Color(hex: 0xFFD166)
    static let modeKiller = Color(hex: 0xFF4560)
    static let modeShanghai = glowViolet
    static let modeHalveIt = glowPink
    static let modePractice170 = Color(hex: 0xFB923C)

    // MARK: Semantic helpers

    static let bust = Color(hex: 0xFF4560)
    static let near = glowTeal

    /// Returns the score-card color for a remaining x01 score.
    static func scoreCardColor(forRemaining remaining: Int) -> Color {
        switch remaining {
        case ...40: return scoreCheckout
        case ...100: return scoreLow
        case ...170: return scoreMid
        default: return scoreHigh
        }
    }

    /// Returns the tint color for a given dart multiplier.
    static func color(for multiplier: Multiplier) -> Color {
        switch multiplier {
        case .single: return single
        case .double: return double
        case .triple: return triple
        }
    }
}

extension Color {
    /// Convenience initializer from a packed RGB hex value, e.g. `0x00E5A0`.
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// Ambient background gradient used behind every screen.
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.glowTeal.opacity(0.22), .clear],
                center: .topLeading, startRadius: 10, endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.glowViolet.opacity(0.20), .clear],
                center: .bottomTrailing, startRadius: 10, endRadius: 460
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.glowPink.opacity(0.12), .clear],
                center: .bottom, startRadius: 10, endRadius: 380
            )
            .ignoresSafeArea()
        }
    }
}
