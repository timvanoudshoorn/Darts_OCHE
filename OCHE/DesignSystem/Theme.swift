import SwiftUI

/// Central color & style palette for OCHE — a warm "pub chalkboard"
/// scoreboard look: deep chalkboard-green panels, wood-grain trim, and
/// chalk-white / marker-colored type.
enum Theme {
    // MARK: Base

    static let background = Color(hex: 0x0E1812)
    static let surface = Color(hex: 0x1B2E22)
    static let surfaceElevated = Color(hex: 0x25402F)
    static let stroke = Color.white.opacity(0.08)

    static let textPrimary = Color(hex: 0xF6F1E7)
    static let textSecondary = Color(hex: 0xF6F1E7).opacity(0.62)
    static let textTertiary = Color(hex: 0xF6F1E7).opacity(0.32)

    // MARK: Wood trim (scoreboard frame)

    static let woodLight = Color(hex: 0xC9A36A)
    static let wood = Color(hex: 0x9C6B3E)
    static let woodDark = Color(hex: 0x5E3C20)

    // MARK: Ambient gradient colors (background glows)

    static let glowTeal = Color(hex: 0x2EE6A6)
    static let glowSky = Color(hex: 0x7EB8FF)
    static let glowPink = Color(hex: 0xF472B6)
    static let glowViolet = Color(hex: 0xC9A6FF)

    // MARK: Multiplier colors (drive number pad re-tint)

    static let single = Color(hex: 0xF6F1E7) // chalk white
    static let double = Color(hex: 0x36D27A) // green marker
    static let triple = Color(hex: 0xFF5A5A) // red marker

    // MARK: Score card thresholds

    static let scoreHigh = Color(hex: 0xF6F1E7)        // > 170
    static let scoreMid = Color(hex: 0x7EB8FF)         // <= 170
    static let scoreLow = Color(hex: 0xFFD166)         // <= 100
    static let scoreCheckout = Color(hex: 0x2EE6A6)    // <= 40 "Checkout range!"

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

    static let bust = Color(hex: 0xFF5A5A)
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

/// Chalkboard background used behind every screen: a deep green-black
/// gradient, soft colored glows, and a faint scattering of chalk dust.
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Color(hex: 0x16281F)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.glowTeal.opacity(0.10), .clear],
                center: .topLeading, startRadius: 10, endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.glowViolet.opacity(0.08), .clear],
                center: .bottomTrailing, startRadius: 10, endRadius: 460
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.glowPink.opacity(0.05), .clear],
                center: .bottom, startRadius: 10, endRadius: 380
            )
            .ignoresSafeArea()

            ChalkDust()
                .ignoresSafeArea()
        }
    }
}

/// A faint, fixed scattering of chalk-dust specks. Generated once with a
/// seeded RNG so the texture is stable across redraws instead of
/// re-randomizing on every frame.
struct ChalkDust: View {
    private static let specks: [(CGFloat, CGFloat, CGFloat, Double)] = {
        var rng = SeededGenerator(seed: 1337)
        return (0..<140).map { _ in
            (
                CGFloat.random(in: 0...1, using: &rng),
                CGFloat.random(in: 0...1, using: &rng),
                CGFloat.random(in: 0.5...2.0, using: &rng),
                Double.random(in: 0.03...0.10, using: &rng)
            )
        }
    }()

    var body: some View {
        Canvas { context, size in
            for (xFrac, yFrac, radius, opacity) in Self.specks {
                let point = CGPoint(x: xFrac * size.width, y: yFrac * size.height)
                let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(Theme.textPrimary.opacity(opacity)))
            }
        }
        .allowsHitTesting(false)
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

/// Wood-grain trim — a warm gradient border used to frame scoreboard panels,
/// evoking a wooden pub chalkboard frame.
struct WoodFrame: ViewModifier {
    var cornerRadius: CGFloat
    var lineWidth: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Theme.woodLight, Theme.wood, Theme.woodDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
    }
}

extension View {
    func woodFrame(cornerRadius: CGFloat, lineWidth: CGFloat = 2) -> some View {
        modifier(WoodFrame(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}

/// A dartboard-style badge: concentric rings in the mode's accent color with
/// the mode's SF Symbol centered on top — used in place of a plain icon tile.
struct DartboardBadge: View {
    var icon: String
    var accent: Color
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.14))
            Circle()
                .strokeBorder(accent.opacity(0.55), lineWidth: 2)
                .padding(6)
            Circle()
                .strokeBorder(accent.opacity(0.30), lineWidth: 1.5)
                .padding(14)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
    }
}
