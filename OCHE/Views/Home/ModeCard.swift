import SwiftUI

/// A Direction F mode-list row: a flat surface card, a solid mode-colored
/// icon badge (no glow/translucency), title and subtitle, and a chevron.
/// Color here is a confident solid fill on the badge only — the card itself
/// stays flat, no per-card glow wash behind it.
struct ModeCard: View {
    let mode: GameMode

    var body: some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: Corner.md)
                    .fill(mode.accentColor)
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.black)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.title)
                    .font(OcheFont.heading(17))
                    .foregroundStyle(Theme.textPrimary)
                Text(mode.subtitle)
                    .font(OcheFont.body(12.5))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: Spacing.sm)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .cardStyle(cornerRadius: Corner.md)
        .clipShape(RoundedRectangle(cornerRadius: Corner.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.title). \(mode.subtitle)")
    }
}
