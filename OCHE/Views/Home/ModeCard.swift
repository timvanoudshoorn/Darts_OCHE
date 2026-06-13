import SwiftUI

/// A colorful home-screen card for one game mode: glowing left-border accent,
/// tinted icon, title and subtitle.
struct ModeCard: View {
    let mode: GameMode

    var body: some View {
        HStack(spacing: 16) {
            DartboardBadge(icon: mode.icon, accent: mode.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title.uppercased())
                    .font(OcheFont.heading(20))
                    .foregroundStyle(Theme.textPrimary)
                Text(mode.subtitle)
                    .font(OcheFont.body(13))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.surface)
        )
        .woodFrame(cornerRadius: 18, lineWidth: 1.5)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .fill(mode.accentColor)
                .frame(width: 4)
                .shadow(color: mode.accentColor.opacity(0.7), radius: 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.title). \(mode.subtitle)")
    }
}
