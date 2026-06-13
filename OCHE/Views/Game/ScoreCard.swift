import SwiftUI

/// Big scoreboard card for the active player. The remaining-score color shifts
/// from cream/white (high) -> sky blue (<=170) -> amber (<=100) -> glowing teal
/// (<=40, "Checkout range!"), per the design system.
struct ScoreCard: View {
    var playerName: String
    var remaining: Int
    var isActive: Bool
    var accent: Color
    var subtitle: String? = nil

    @State private var bustShake: CGFloat = 0
    @State private var slamScale: CGFloat = 1.0
    @State private var ringPulse = false

    private var color: Color { Theme.scoreCardColor(forRemaining: remaining) }
    private var isCheckoutRange: Bool { remaining <= 40 && remaining > 0 }

    /// Big score numbers use the signature cyan→violet gradient while in the
    /// "high" range; lower ranges keep their semantic warning colors.
    private var scoreStyle: AnyShapeStyle {
        remaining > 170 ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(color)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(isActive ? accent : Theme.textTertiary)
                    .frame(width: 8, height: 8)
                Text(playerName.uppercased())
                    .font(OcheFont.label(14))
                    .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
                if isCheckoutRange {
                    Text("CHECKOUT RANGE!")
                        .font(OcheFont.label(11))
                        .foregroundStyle(Theme.scoreCheckout)
                }
            }

            VStack(spacing: 2) {
                Rectangle().fill(Theme.textTertiary).frame(height: 1)
                Rectangle().fill(Theme.textTertiary).frame(height: 1)
            }
            .opacity(0.5)

            Text("\(remaining)")
                .font(OcheFont.scoreDisplay(isActive ? 84 : 56))
                .foregroundStyle(scoreStyle)
                .contentTransition(.numericText())
                .scaleEffect(slamScale)
                .offset(x: bustShake)
                .animation(.default, value: remaining)

            if let subtitle {
                Text(subtitle)
                    .font(OcheFont.body(13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.surface)
        )
        .woodFrame(cornerRadius: 20, lineWidth: 1.5)
        .overlay(
            Group {
                if isActive {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.accentGradient, lineWidth: 2)
                        .opacity(ringPulse ? 1.0 : 0.55)
                }
            }
        )
        .shadow(color: isActive ? accent.opacity(0.25) : .clear, radius: 16)
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    ringPulse = true
                }
            }
        }
        .onChange(of: isActive) { active in
            if active {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    ringPulse = true
                }
            } else {
                ringPulse = false
            }
        }
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
