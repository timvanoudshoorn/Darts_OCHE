import SwiftUI

/// Type ramp built on **Rajdhani** — a condensed, geometric sports/esports
/// typeface (think broadcast scoreboards and gaming HUDs). Bundled as static
/// weights and registered at launch by `FontLoader`, so these faces resolve by
/// PostScript name. If a face ever fails to load, SwiftUI falls back to the
/// system font gracefully.
enum OcheFont {
    // PostScript names of the bundled Rajdhani faces.
    private static let bold = "Rajdhani-Bold"
    private static let semibold = "Rajdhani-SemiBold"
    private static let medium = "Rajdhani-Medium"
    private static let regular = "Rajdhani-Regular"

    /// Big scoreboard numbers (remaining score, totals).
    static func scoreDisplay(_ size: CGFloat = 96) -> Font {
        .custom(bold, size: size)
    }

    /// Section headings, mode titles.
    static func heading(_ size: CGFloat = 28) -> Font {
        .custom(semibold, size: size)
    }

    /// Number pad buttons.
    static func button(_ size: CGFloat = 30) -> Font {
        .custom(semibold, size: size)
    }

    /// Small uppercase labels / eyebrow text.
    static func label(_ size: CGFloat = 13) -> Font {
        .custom(medium, size: size)
    }

    /// Body copy.
    static func body(_ size: CGFloat = 16) -> Font {
        .custom(regular, size: size)
    }

    static func bodyBold(_ size: CGFloat = 16) -> Font {
        .custom(medium, size: size)
    }
}

/// Applies the uppercase tracking style used across headings and labels.
struct UppercaseImpact: ViewModifier {
    var size: CGFloat
    var color: Color = Theme.textPrimary

    func body(content: Content) -> some View {
        content
            .font(OcheFont.heading(size))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(color)
    }
}

extension View {
    func ocheHeading(_ size: CGFloat = 28, color: Color = Theme.textPrimary) -> some View {
        modifier(UppercaseImpact(size: size, color: color))
    }
}
