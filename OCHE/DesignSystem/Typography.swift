import SwiftUI

/// Type ramp built around iOS's built-in "Chalkboard SE" and "Marker Felt"
/// fonts — these ship with every iOS device, so headings, scoreboard
/// numbers, and button labels get a genuine hand-chalked / marker-board feel
/// with no font files to bundle. Body copy uses the rounded system font for
/// readability, and everything degrades gracefully on Dynamic Type.
enum OcheFont {
    /// Big scoreboard numbers (remaining score, totals).
    static func scoreDisplay(_ size: CGFloat = 96) -> Font {
        .custom("ChalkboardSE-Bold", size: size, relativeTo: .largeTitle)
    }

    /// Section headings, mode titles.
    static func heading(_ size: CGFloat = 28) -> Font {
        .custom("ChalkboardSE-Bold", size: size, relativeTo: .title)
    }

    /// Number pad buttons.
    static func button(_ size: CGFloat = 30) -> Font {
        .custom("ChalkboardSE-Bold", size: size, relativeTo: .title3)
    }

    /// Small uppercase labels / eyebrow text.
    static func label(_ size: CGFloat = 13) -> Font {
        .custom("ChalkboardSE-Regular", size: size, relativeTo: .caption)
    }

    /// Body copy uses the rounded system font for readability.
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func bodyBold(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
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
