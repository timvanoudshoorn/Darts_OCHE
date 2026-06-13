import SwiftUI

/// Type ramp built on the system font in its **condensed** width and heavy
/// weights — a bold, digital sports-scoreboard look (think LED scoreboards
/// and broadcast graphics) with zero bundled font files. Body copy uses the
/// rounded system font for readability, and everything degrades gracefully
/// on Dynamic Type.
enum OcheFont {
    /// Big scoreboard numbers (remaining score, totals).
    static func scoreDisplay(_ size: CGFloat = 96) -> Font {
        .system(size: size, weight: .black, design: .default).width(.condensed)
    }

    /// Section headings, mode titles.
    static func heading(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .default).width(.condensed)
    }

    /// Number pad buttons.
    static func button(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .bold, design: .default).width(.condensed)
    }

    /// Small uppercase labels / eyebrow text.
    static func label(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .bold, design: .default).width(.condensed)
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
