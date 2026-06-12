import SwiftUI

/// "Juicy" press feedback: a quick spring squash on tap. Doesn't add any delay —
/// the action fires immediately on press-down via `onTapGesture`-less `Button`,
/// so rapid-fire input is never blocked by the animation.
struct SquashButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.45), value: configuration.isPressed)
    }
}

/// A ripple of color that expands and fades from the tap point. Purely
/// decorative and non-blocking — it animates independently of input.
struct RippleBurst: View {
    var color: Color
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color.opacity(animate ? 0 : 0.35))
            .scaleEffect(animate ? 2.4 : 0.2)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    animate = true
                }
            }
    }
}
