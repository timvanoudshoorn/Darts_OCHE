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
                .frame(maxWidth: .infinity)
                NumberPadButton(dart: Dart.miss, state: .normal, accent: accent, customLabel: "MISS") {
                    onThrow(Dart.miss)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Single/Double/Triple selector — re-colors the entire pad below it. The
/// active multiplier gets a confident solid fill (the one moment of color
/// here); resting tabs stay flat, matching Direction F's "glow/fill is
/// reserved for the active choice, not default chrome" principle.
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
                                .fill(isActive ? mult.color : Theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isActive ? Color.clear : Theme.stroke, lineWidth: 1)
                        )
                        .foregroundStyle(isActive ? Color.black : Theme.textSecondary)
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
                    .fill(Theme.surface)
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
                            .foregroundStyle(Color.black.opacity(0.65))
                    } else if state == .near {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.near)
                    }
                }
            }
            .frame(height: 56)
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

    /// The exact-checkout button gets a confident *solid* fill (not just a
    /// tint) — it's the one button on the pad that should visually shout;
    /// everything else stays a light tint at most.
    private var stateTint: Color {
        switch state {
        case .checkout: return baseColor
        case .bust: return Theme.bust.opacity(0.10)
        case .near: return Theme.near.opacity(0.14)
        case .target: return accent.opacity(0.16)
        case .normal: return .clear
        }
    }

    private var borderColor: Color {
        switch state {
        case .checkout: return Color.clear
        case .bust: return Theme.bust.opacity(0.45)
        case .near: return Theme.near
        case .target: return accent
        case .normal: return Theme.stroke
        }
    }

    private var borderWidth: CGFloat {
        switch state {
        case .target: return 2
        case .near: return 1.5
        default: return 1
        }
    }

    private var textColor: Color {
        if dart.isMiss { return Theme.textSecondary }
        if state == .checkout { return Color.black }
        return baseColor
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
