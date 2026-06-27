import SwiftUI

/// Central color & style palette for OCHE — "Direction F: Tour Ready":
/// a near-black navy canvas, hairline-bordered surfaces (depth via elevation
/// and shadow, not glow), and one confident brand accent instead of the old
/// cyan→violet gradient.
///
/// Property *names* below are unchanged from the original "Direction C"
/// palette (touching every one of their ~200 call sites across the app
/// wasn't worth the risk) but most *values* are new — see each property's
/// comment for what it actually renders as now. The one real bug fix baked
/// in here: `bust` used to be aliased to the same color as `triple`-hits
/// (both were `magenta`), so a bust and a triple-20 looked identical. They're
/// now genuinely distinct colors.
enum Theme {
    // MARK: Base

    static let background = Color(hex: 0x0B0D12)
    static let surface = Color(hex: 0x161922)
    static let surfaceElevated = Color(hex: 0x1E222E)
    static let stroke = Color.white.opacity(0.07)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.28)

    // MARK: Accent palette

    /// The single brand accent ("oche" red/orange) — was the cyan half of
    /// the old gradient; now the one confident accent used everywhere.
    static let cyan = Color(hex: 0xFF5C39)
    /// Secondary tint for triple-hits / Halve-It — genuinely distinct from
    /// both the brand accent and `bust` (previously this and `magenta`
    /// were the same color as `bust`).
    static let violet = Color(hex: 0x8B7CF6)
    static let magenta = Color(hex: 0x8B7CF6)
    static let green = Color(hex: 0x2FBE7A)
    static let amber = Color(hex: 0xF0B23E)

    /// Was a cyan→violet gradient; Direction F uses one confident accent
    /// instead, so both stops are the same color — every call site that
    /// renders this (big score numbers, headings, active-state borders)
    /// now gets a flat brand-accent fill rather than a rainbow blend.
    static let accentGradient = LinearGradient(
        colors: [cyan, cyan],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: Ambient gradient colors (background glows) — kept as aliases
    // so existing call sites continue to compile.

    static let glowTeal = green
    static let glowSky = cyan
    static let glowPink = violet
    static let glowViolet = violet

    // MARK: Multiplier colors (drive number pad re-tint)

    static let single = Color.white
    static let double = green
    static let triple = violet

    // MARK: Score card thresholds

    static let scoreHigh = Color.white          // > 170
    static let scoreMid = cyan                   // <= 170
    static let scoreLow = amber                  // <= 100
    static let scoreCheckout = green             // <= 40 "Checkout range!"

    // MARK: Game mode accent colors

    static let modeAroundClock = green
    static let modeStandard = cyan
    static let modeCricket = Color(hex: 0x1FB6A6)
    static let modeCountUp = amber
    static let modeKiller = Color(hex: 0xFF4560)
    static let modeHalveIt = violet
    static let modePractice170 = Color(hex: 0xFB923C)

    // MARK: Semantic helpers

    /// Genuinely distinct from `triple`/`magenta` now — see the type's doc
    /// comment for the bug this fixes.
    static let bust = Color(hex: 0xE2364A)
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

/// Flat near-black background used behind every screen, with a single
/// restrained accent glow at the top — Direction F reserves glow for state
/// (active player, checkout range), not decoration, so this is deliberately
/// calmer than the old two-color corner-glow treatment.
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.cyan.opacity(0.08), .clear],
                center: .top, startRadius: 10, endRadius: 520
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

    /// A flat brand-accent border — used for active-player cards and popups.
    func gradientBorder(cornerRadius: CGFloat, lineWidth: CGFloat = 1.5) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Theme.accentGradient, lineWidth: lineWidth)
        )
    }

    /// The standard flat surface card: `Theme.surface` fill + a hairline
    /// border, replacing the `RoundedRectangle(...).fill(...).overlay(...)`
    /// pair duplicated across nearly every card in the app. Pass
    /// `isHighlighted` for active/winner states (a colored, thicker border
    /// instead of the default hairline). Composes fine with trailing
    /// modifiers like `.shadow(...)` chained after it.
    func cardStyle(cornerRadius: CGFloat = Corner.lg, isHighlighted: Bool = false, highlightColor: Color = Theme.cyan) -> some View {
        background(RoundedRectangle(cornerRadius: cornerRadius).fill(Theme.surface))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(isHighlighted ? highlightColor.opacity(0.5) : Theme.stroke, lineWidth: isHighlighted ? 2 : 1)
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
