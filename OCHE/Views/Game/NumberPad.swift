import SwiftUI

/// Visual state for a single number pad button, decided by the game engine
/// for the *current* multiplier/target.
enum NumberPadCellState: Equatable {
    /// Plain scoring button.
    case normal
    /// Hitting this would score against the current target (Around the Clock /
    /// Cricket open number) — accent-colored ring.
    case target
    /// Hitting this lands in checkout range (but isn't the checkout itself) —
    /// teal "near-out" highlight with a → arrow.
    case near
    /// Hitting this is the *exact* checkout — glows/pulses with "OUT ✓".
    case checkout
    /// Hitting this would bust — dimmed red.
    case bust
}

/// The number pad — re-tints entirely based on the active multiplier
/// (Single = cream, Double = green, Triple = red) and surfaces per-button
/// state (checkout / bust / near-out / target) computed by the active engine.
///
/// Designed for one-handed reach: lives in the lower portion of the screen
/// with large, dense buttons so the whole board is reachable by thumb.
struct NumberPad: View {
    @Binding var multiplier: Multiplier
    var accent: Color

    /// Computes the visual state for a candidate dart. Engines that don't
    /// need a particular state (e.g. Cricket has no "bust") simply never
    /// return it.
    var stateFor: (Dart) -> NumberPadCellState

    /// Whether the bull button should allow Triple (it never does on a real
    /// board — handled automatically by `Dart.init`, this just controls the
    /// displayed multiplier).
    var onThrow: (Dart) -> Void

    private let numbers = Array((1...20).reversed())
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 12) {
            MultiplierSelector(multiplier: $multiplier)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(numbers, id: \.self) { n in
                    let dart = Dart(value: n, multiplier: multiplier)
                    NumberPadButton(dart: dart, state: stateFor(dart), accent: accent) {
                        onThrow(dart)
                    }
                }
            }

            HStack(spacing: 8) {
                let bullMultiplier: Multiplier = multiplier == .triple ? .double : multiplier
                let bullDart = Dart(value: 25, multiplier: bullMultiplier)
                NumberPadButton(dart: bullDart, state: stateFor(bullDart), accent: accent, customLabel: bullMultiplier == .double ? "D-BULL" : "BULL") {
                    onThrow(bullDart)
                }
                NumberPadButton(dart: Dart.miss, state: .normal, accent: accent, customLabel: "MISS") {
                    onThrow(Dart.miss)
                }
            }
        }
    }
}

/// Single/Double/Triple selector — re-colors the entire pad below it.
struct MultiplierSelector: View {
    @Binding var multiplier: Multiplier

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Multiplier.allCases) { mult in
                let isActive = multiplier == mult
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        multiplier = mult
                    }
                } label: {
                    Text(mult.fullName.uppercased())
                        .font(OcheFont.button(18))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isActive ? mult.color.opacity(0.22) : Theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isActive ? mult.color : Theme.stroke, lineWidth: isActive ? 2 : 1)
                        )
                        .foregroundStyle(isActive ? mult.color : Theme.textSecondary)
                }
                .buttonStyle(SquashButtonStyle())
            }
        }
    }
}

/// One scoring button. Re-tints based on `dart.multiplier` and overlays the
/// `state` (checkout glow, bust dim, near-out arrow, target ring).
struct NumberPadButton: View {
    let dart: Dart
    let state: NumberPadCellState
    let accent: Color
    var customLabel: String? = nil
    let action: () -> Void

    @State private var pulse = false
    @State private var ripple = false

    private var baseColor: Color {
        dart.isMiss ? Theme.textSecondary : dart.multiplier.color
    }

    var body: some View {
        Button {
            ripple = false
            DispatchQueue.main.async { ripple = true }
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.surfaceElevated, Theme.surface],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 16)
                    .fill(stateTint)
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: borderWidth)

                if ripple {
                    RippleBurst(color: baseColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) { ripple = false }
                        }
                }

                VStack(spacing: 2) {
                    Text(customLabel ?? "\(dart.value)")
                        .font(OcheFont.button(26))
                        .foregroundStyle(textColor)

                    if state == .checkout {
                        Text("OUT ✓")
                            .font(OcheFont.label(11))
                            .foregroundStyle(baseColor)
                    } else if state == .near {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.near)
                    }
                }
            }
            .frame(height: 56)
            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        }
        .buttonStyle(SquashButtonStyle())
        .scaleEffect(state == .checkout && pulse ? 1.06 : 1.0)
        .onAppear {
            if state == .checkout {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .onChange(of: state) { newValue in
            pulse = (newValue == .checkout)
        }
        .opacity(state == .bust ? 0.45 : 1.0)
        .accessibilityLabel(accessibilityLabel)
    }

    private var stateTint: Color {
        switch state {
        case .checkout: return baseColor.opacity(0.30)
        case .bust: return Theme.bust.opacity(0.12)
        case .near: return Theme.near.opacity(0.16)
        case .target: return accent.opacity(0.18)
        case .normal: return .clear
        }
    }

    private var borderColor: Color {
        switch state {
        case .checkout: return baseColor
        case .bust: return Theme.bust.opacity(0.5)
        case .near: return Theme.near
        case .target: return accent
        case .normal: return Theme.stroke
        }
    }

    private var borderWidth: CGFloat {
        switch state {
        case .checkout, .target: return 2
        case .near: return 1.5
        default: return 1
        }
    }

    private var textColor: Color {
        dart.isMiss ? Theme.textSecondary : baseColor
    }

    private var accessibilityLabel: String {
        var label = dart.fullLabel
        switch state {
        case .checkout: label += ", checkout available"
        case .bust: label += ", would bust"
        case .near: label += ", checkout range"
        case .target: label += ", target number"
        case .normal: break
        }
        return label
    }
}
