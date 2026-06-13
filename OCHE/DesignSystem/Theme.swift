import SwiftUI

/// Central color & style palette for OCHE — "Modern Minimalist Esports":
/// a flat near-black canvas, glassy surfaces, and a signature cyan→violet
/// gradient used for primary accents, big score numbers, and active-state
/// borders/glows.
enum Theme {
    // MARK: Base

    static let background = Color(hex: 0x0A0B10)
    static let surface = Color(hex: 0x14161F)
    static let surfaceElevated = Color(hex: 0x1B1E2B)
    static let stroke = Color.white.opacity(0.06)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.28)

    // MARK: Accent palette

    static let cyan = Color(hex: 0x2DE0FF)
    static let violet = Color(hex: 0x9B6BFF)
    static let magenta = Color(hex: 0xFF5FB8)
    static let green = Color(hex: 0x3CE6A6)
    static let amber = Color(hex: 0xFFC857)

    /// The signature cyan→violet gradient used for big score numbers,
    /// active-player borders, and popup highlights.
    static let accentGradient = LinearGradient(
        colors: [cyan, violet],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: Ambient gradient colors (background glows) — kept as aliases
    // onto the Direction C accent palette so existing call sites continue
    // to compile.

    static let glowTeal = green
    static let glowSky = cyan
    static let glowPink = magenta
    static let glowViolet = violet

    // MARK: Multiplier colors (drive number pad re-tint)

    static let single = Color.white
    static let double = green
    static let triple = magenta

    // MARK: Score card thresholds

    static let scoreHigh = Color.white          // > 170
    static let scoreMid = cyan                   // <= 170
    static let scoreLow = amber                  // <= 100
    static let scoreCheckout = green             // <= 40 "Checkout range!"

    // MARK: Game mode accent colors

    static let modeAroundClock = green
    static let modeStandard = cyan
    static let modeCricket = magenta
    static let modeCountUp = amber
    static let modeKiller = Color(hex: 0xFF4560)
    static let modeHalveIt = violet
    static let modePractice170 = Color(hex: 0xFB923C)

    // MARK: Semantic helpers

    static let bust = magenta
    static let near = green

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

/// Flat near-black background used behind every screen, with two soft
/// cyan/violet radial glows in the corners — the Direction C signature.
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.cyan.opacity(0.16), .clear],
                center: .topTrailing, startRadius: 10, endRadius: 460
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.violet.opacity(0.18), .clear],
                center: .bottomLeading, startRadius: 10, endRadius: 480
            )
            .ignoresSafeArea()
        }
    }
}

/// Deterministic pseudo-random generator so decorative textures look the
/// same on every launch instead of jittering on each redraw.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// Glassy card edge — a faint hairline border used to lift cards off the
/// near-black background, evoking frosted-glass panels.
struct WoodFrame: ViewModifier {
    var cornerRadius: CGFloat
    var lineWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Theme.stroke, lineWidth: lineWidth)
            )
    }
}

extension View {
    func woodFrame(cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        modifier(WoodFrame(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }

    /// A gradient-edge border using the signature cyan→violet accent —
    /// used for active-player cards and popups.
    func gradientBorder(cornerRadius: CGFloat, lineWidth: CGFloat = 1.5) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Theme.accentGradient, lineWidth: lineWidth)
        )
    }
}

/// A mode badge: a rounded-square glass tile with the mode's SF Symbol
/// centered on top in its accent color — used in place of a plain icon tile.
struct DartboardBadge: View {
    var icon: String
    var accent: Color
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(Theme.surfaceElevated)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
    }
}
