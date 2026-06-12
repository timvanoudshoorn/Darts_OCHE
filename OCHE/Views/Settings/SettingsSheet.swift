import SwiftUI

/// Bottom-sheet settings panel: feedback toggles bound to `SettingsStore`.
struct SettingsSheet: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("SETTINGS")
                        .font(OcheFont.heading(24))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    toggleRow("Sound Effects", icon: "speaker.wave.2.fill", isOn: $settings.soundEnabled)
                    divider
                    toggleRow("Haptics", icon: "iphone.radiowaves.left.and.right", isOn: $settings.hapticsEnabled)
                    divider
                    toggleRow("Particles", icon: "sparkles", isOn: $settings.particlesEnabled)
                    divider
                    toggleRow("Popups", icon: "bubble.middle.top.fill", isOn: $settings.popupsEnabled)
                    divider
                    toggleRow("Screen Flash", icon: "bolt.fill", isOn: $settings.flashEnabled)
                }
                .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.stroke, lineWidth: 1))

                Spacer()

                VStack(spacing: 4) {
                    Text("OCHE")
                        .font(OcheFont.heading(18))
                    Text("Free forever. No account required.")
                        .font(OcheFont.body(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
            }
            .padding(20)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var divider: some View {
        Divider().overlay(Theme.stroke)
    }

    private func toggleRow(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(OcheFont.bodyBold(15))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .tint(Theme.glowTeal)
        .padding(16)
    }
}
