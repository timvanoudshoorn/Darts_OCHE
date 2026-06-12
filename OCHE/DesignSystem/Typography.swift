import SwiftUI

/// Type ramp built around 'Barlow Condensed' (heavy weight) for numbers/headings,
/// with the system font for body copy. Both register their custom font and fall
/// back gracefully (and support Dynamic Type) if the font isn't bundled yet.
enum OcheFont {
    /// Big scoreboard numbers (remaining score, totals).
    static func scoreDisplay(_ size: CGFloat = 96) -> Font {
        .custom("BarlowCondensed-Black", size: size, relativeTo: .largeTitle)
    }

    /// Section headings, mode titles.
    static func heading(_ size: CGFloat = 28) -> Font {
        .custom("BarlowCondensed-Black", size: size, relativeTo: .title)
    }

    /// Number pad buttons.
    static func button(_ size: CGFloat = 30) -> Font {
        .custom("BarlowCondensed-Bold", size: size, relativeTo: .title3)
    }

    /// Small uppercase labels / eyebrow text.
    static func label(_ size: CGFloat = 13) -> Font {
        .custom("BarlowCondensed-SemiBold", size: size, relativeTo: .caption)
    }

    /// Body copy uses the system sans-serif for readability.
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func bodyBold(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .default)
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
