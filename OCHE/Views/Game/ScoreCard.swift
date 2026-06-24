import SwiftUI

/// Broadcast "lower-third" scoreboard card for one player: a left accent bar
/// (colored when active, muted gray otherwise) instead of a glowing border —
/// Direction F reserves color/glow for genuine state, not default chrome.
/// The remaining-score number stays neutral white and only shifts color when
/// truly in checkout range (<=40), rather than cycling through a tier of
/// colors as the score drops.
struct ScoreCard: View {
    var playerName: String
    var remaining: Int
    var isActive: Bool
    var accent: Color
    var subtitle: String? = nil

    @State private var bustShake: CGFloat = 0
    @State private var slamScale: CGFloat = 1.0

    private var isCheckoutRange: Bool { remaining <= 40 && remaining > 0 }
    private var scoreColor: Color { isCheckoutRange ? Theme.scoreCheckout : Theme.textPrimary }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isActive ? accent : Theme.textTertiary.opacity(0.4))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(playerName.uppercased())
                        .font(OcheFont.label(12))
                        .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                    Spacer()
                    if isCheckoutRange {
                        Text("CHECKOUT")
                            .font(OcheFont.label(10))
                            .foregroundStyle(Theme.scoreCheckout)
                    }
                }

                Text("\(remaining)")
                    .font(OcheFont.scoreDisplay(isActive ? 64 : 44))
                    .foregroundStyle(scoreColor)
                    .contentTransition(.numericText())
                    .scaleEffect(slamScale)
                    .offset(x: bustShake)
                    .animation(.default, value: remaining)

                if let subtitle {
                    Text(subtitle)
                        .font(OcheFont.body(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? Theme.surfaceElevated : Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onChange(of: remaining) { _ in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                slamScale = 1.06
            }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4).delay(0.08)) {
                slamScale = 1.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(playerName), \(remaining) remaining\(isActive ? ", current turn" : "")")
    }

    /// Triggers the red "shake" animation used for busts.
    func shakeForBust() {
        withAnimation(.default) { bustShake = -10 }
        withAnimation(.default.delay(0.06)) { bustShake = 10 }
        withAnimation(.default.delay(0.12)) { bustShake = -6 }
        withAnimation(.default.delay(0.18)) { bustShake = 0 }
    }
}

/// Shows the up-to-3 darts thrown this turn as small chips.
struct DartsThisTurnView: View {
    var darts: [Dart]
    var accent: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                let dart = i < darts.count ? darts[i] : nil
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(dart != nil ? (dart?.multiplier.color ?? accent) : Theme.stroke, lineWidth: 1.5)
                        )
                    if let dart {
                        Text(dart.label)
                            .font(OcheFont.button(16))
                            .foregroundStyle(dart.multiplier.color)
                    }
                }
                .frame(width: 56, height: 36)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(darts.isEmpty ? "No darts thrown yet this turn" : "Thrown: " + darts.map(\.fullLabel).joined(separator: ", "))
    }
}
