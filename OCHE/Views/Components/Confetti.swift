import SwiftUI

/// A short burst of falling, tumbling confetti pieces — used to celebrate
/// checkouts and match wins. Purely decorative, non-blocking, and removes
/// itself after the animation finishes.
struct ConfettiBurst: View {
    private static let colors: [Color] = [
        Theme.scoreCheckout, Theme.glowSky, Theme.glowPink, Theme.glowViolet,
        Theme.modeCountUp, Theme.modeCricket, Theme.woodLight
    ]

    private struct Piece: Identifiable {
        let id = UUID()
        let xFraction: CGFloat
        let color: Color
        let size: CGFloat
        let delay: Double
        let duration: Double
        let rotations: Double
        let drift: CGFloat
    }

    private let pieces: [Piece]

    init(count: Int = 40) {
        var rng = SeededGenerator(seed: UInt64(Date().timeIntervalSinceReferenceDate * 1000))
        pieces = (0..<count).map { _ in
            Piece(
                xFraction: CGFloat.random(in: 0...1, using: &rng),
                color: Self.colors.randomElement(using: &rng) ?? Theme.scoreCheckout,
                size: CGFloat.random(in: 6...12, using: &rng),
                delay: Double.random(in: 0...0.25, using: &rng),
                duration: Double.random(in: 1.0...1.8, using: &rng),
                rotations: Double.random(in: 1...3, using: &rng) * (Bool.random(using: &rng) ? 1 : -1),
                drift: CGFloat.random(in: -60...60, using: &rng)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPiece(piece: piece, height: geo.size.height)
                        .position(x: piece.xFraction * geo.size.width, y: -20)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private struct ConfettiPiece: View {
        let piece: Piece
        let height: CGFloat

        @State private var fallen = false

        var body: some View {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size * 0.4)
                .rotationEffect(.degrees(fallen ? piece.rotations * 360 : 0))
                .offset(x: fallen ? piece.drift : 0, y: fallen ? height + 40 : 0)
                .opacity(fallen ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                        fallen = true
                    }
                }
        }
    }
}
