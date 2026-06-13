import SwiftUI

/// Shared top bar for every game screen: quit, mode title, multi-step undo,
/// and settings — all within easy thumb reach since they sit at the top but
/// are large tap targets.
struct GameTopBar: View {
    var title: String
    var accent: Color
    var canUndo: Bool
    var onUndo: () -> Void
    var onSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onQuit) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.surface))
                    .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1.5))
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityLabel("Quit match")

            Text(title.uppercased())
                .font(OcheFont.heading(20))
                .foregroundStyle(accent)
                .lineLimit(1)

            Spacer()

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.surface))
                    .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1.5))
                    .foregroundStyle(canUndo ? Theme.textPrimary : Theme.textTertiary)
            }
            .disabled(!canUndo)
            .accessibilityLabel("Undo last dart")

            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.surface))
                    .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1.5))
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityLabel("Settings")
        }
        .buttonStyle(SquashButtonStyle())
    }
}
