import SwiftUI

/// A premium home-screen card for one game mode: a glassy panel lit by a soft
/// mode-colored glow on the leading edge, a glowing icon badge, the title and
/// subtitle, and a tinted chevron.
struct ModeCard: View {
    let mode: GameMode

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(mode.accentColor.opacity(0.16))
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(mode.accentColor.opacity(0.55), lineWidth: 1)
                Image(systemName: mode.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(mode.accentColor)
            }
            .frame(width: 56, height: 56)
            .shadow(color: mode.accentColor.opacity(0.45), radius: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.title.uppercased())
                    .font(OcheFont.heading(21))
                    .foregroundStyle(Theme.textPrimary)
                Text(mode.subtitle)
                    .font(OcheFont.body(13))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(mode.accentColor.opacity(0.7))
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.surface)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            colors: [mode.accentColor.opacity(0.20), .clear],
                            center: .leading, startRadius: 4, endRadius: 240
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.title). \(mode.subtitle)")
    }
}
