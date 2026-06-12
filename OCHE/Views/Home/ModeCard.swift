import SwiftUI

/// A colorful home-screen card for one game mode: glowing left-border accent,
/// tinted icon, title and subtitle.
struct ModeCard: View {
    let mode: GameMode

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(mode.accentColor.opacity(0.16))
                Image(systemName: mode.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(mode.accentColor)
            }
            .frame(width: 52, height: 52)

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
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
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
