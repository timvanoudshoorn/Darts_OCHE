import SwiftUI

/// A reactive, authentically-colored dartboard graphic. Pass the darts thrown
/// this turn as `hits` to drop animated markers where they landed, and set
/// `flashDart` to briefly glow the segment that was just hit.
///
/// Geometry is computed once per draw from the available size, so the same
/// view works as a small home-screen hero or a large in-game centerpiece.
struct Dartboard: View {
    var hits: [Dart] = []
    var flashDart: Dart? = nil

    /// Around the Clock: segments already completed by the active player,
    /// dimmed/highlighted in green. `25` represents Bull.
    var completedSegments: Set<Int> = []
    /// Around the Clock: the active player's current target — highlighted
    /// with a gold ring. `25` represents Bull.
    var targetSegment: Int? = nil

    /// Standard board order, clockwise starting from the top (12 o'clock).
    static let segmentOrder = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    // Radii as fractions of the board radius `r`.
    private let bullInner: CGFloat = 0.05
    private let bullOuter: CGFloat = 0.13
    private let tripleInner: CGFloat = 0.48
    private let tripleOuter: CGFloat = 0.58
    private let doubleInner: CGFloat = 0.80
    private let doubleOuter: CGFloat = 0.88
    private let rimOuter: CGFloat = 0.94

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let r = size / 2
            let center = CGPoint(x: r, y: r)

            ZStack {
                Canvas { context, _ in
                    drawBoard(context: context, center: center, r: r)
                    drawAroundClockOverlays(context: context, center: center, r: r)
                }

                ForEach(Array(Self.segmentOrder.enumerated()), id: \.offset) { index, value in
                    Text("\(value)")
                        .font(OcheFont.label(max(9, r * 0.09)))
                        .foregroundStyle(Theme.textPrimary)
                        .position(point(center: center, radius: r * 0.97, angle: angle(for: index, offsetDeg: 0)))
                }

                if let flashDart {
                    FlashHighlight(dart: flashDart, r: r)
                        .id(flashDart.id)
                }

                ForEach(hits) { hit in
                    DartMarker(dart: hit, center: center, r: r)
                }
            }
            .frame(width: size, height: size)
            .animation(.easeOut(duration: 0.25), value: hits)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Drawing

    private func drawBoard(context: GraphicsContext, center: CGPoint, r: CGFloat) {
        // Wooden surround + black wire rim.
        context.fill(Path(ellipseIn: rect(center: center, radius: r)), with: .color(Theme.surfaceElevated))
        context.fill(Path(ellipseIn: rect(center: center, radius: r * rimOuter)), with: .color(.black))

        for index in 0..<20 {
            let isDark = index % 2 == 0
            let singleColor: Color = isDark ? Color(hex: 0x14140F) : Color(hex: 0xEDE3CF)
            let ringColor: Color = isDark ? Color(hex: 0x1E8E4F) : Color(hex: 0xD93B3B)
            let start = angle(for: index, offsetDeg: -9)
            let end = angle(for: index, offsetDeg: 9)

            context.fill(wedge(center: center, innerR: r * doubleInner, outerR: r * doubleOuter, start: start, end: end), with: .color(ringColor))
            context.fill(wedge(center: center, innerR: r * tripleOuter, outerR: r * doubleInner, start: start, end: end), with: .color(singleColor))
            context.fill(wedge(center: center, innerR: r * tripleInner, outerR: r * tripleOuter, start: start, end: end), with: .color(ringColor))
            context.fill(wedge(center: center, innerR: r * bullOuter, outerR: r * tripleInner, start: start, end: end), with: .color(singleColor))
        }

        context.fill(Path(ellipseIn: rect(center: center, radius: r * bullOuter)), with: .color(Color(hex: 0x1E8E4F)))
        context.fill(Path(ellipseIn: rect(center: center, radius: r * bullInner)), with: .color(Color(hex: 0xD93B3B)))

        for index in 0..<20 {
            let a = angle(for: index, offsetDeg: -9)
            var divider = Path()
            divider.move(to: point(center: center, radius: r * bullOuter, angle: a))
            divider.addLine(to: point(center: center, radius: r * doubleOuter, angle: a))
            context.stroke(divider, with: .color(.black.opacity(0.55)), lineWidth: max(0.5, r * 0.004))
        }
    }

    /// Draws Around the Clock highlight overlays: completed segments tinted
    /// green, and the active target ringed in gold (Theme.amber).
    private func drawAroundClockOverlays(context: GraphicsContext, center: CGPoint, r: CGFloat) {
        for value in completedSegments where value != 25 {
            guard let index = Self.segmentOrder.firstIndex(of: value) else { continue }
            let start = angle(for: index, offsetDeg: -9)
            let end = angle(for: index, offsetDeg: 9)
            context.fill(wedge(center: center, innerR: r * bullOuter, outerR: r * doubleOuter, start: start, end: end), with: .color(Theme.green.opacity(0.35)))
        }

        if let target = targetSegment, target != 25, let index = Self.segmentOrder.firstIndex(of: target) {
            let start = angle(for: index, offsetDeg: -9)
            let end = angle(for: index, offsetDeg: 9)
            let path = wedge(center: center, innerR: r * bullOuter, outerR: r * doubleOuter, start: start, end: end)
            context.stroke(path, with: .color(Theme.amber), lineWidth: max(2, r * 0.02))
        }

        if targetSegment == 25 {
            context.stroke(Path(ellipseIn: rect(center: center, radius: r * tripleInner)), with: .color(Theme.amber), lineWidth: max(2, r * 0.02))
        }

        if completedSegments.contains(25) {
            context.fill(Path(ellipseIn: rect(center: center, radius: r * bullOuter)), with: .color(Theme.green.opacity(0.35)))
        }
    }

    // MARK: Geometry helpers

    private func angle(for index: Int, offsetDeg: Double) -> Angle {
        .degrees(-90 + Double(index) * 18 + offsetDeg)
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)), y: center.y + radius * CGFloat(sin(angle.radians)))
    }

    private func rect(center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    private func wedge(center: CGPoint, innerR: CGFloat, outerR: CGFloat, start: Angle, end: Angle) -> Path {
        var path = Path()
        path.move(to: point(center: center, radius: innerR, angle: start))
        path.addLine(to: point(center: center, radius: outerR, angle: start))
        path.addArc(center: center, radius: outerR, startAngle: start, endAngle: end, clockwise: false)
        path.addLine(to: point(center: center, radius: innerR, angle: end))
        path.addArc(center: center, radius: innerR, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

/// An annular wedge (one board segment, at one ring) as a `Shape`, used so
/// the checkout/hit flash can be drawn with SwiftUI fill + animatable opacity.
private struct WedgeShape: Shape {
    var index: Int
    var innerFrac: CGFloat
    var outerFrac: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = Angle.degrees(-90 + Double(index) * 18 - 9)
        let end = Angle.degrees(-90 + Double(index) * 18 + 9)

        func pt(_ radius: CGFloat, _ angle: Angle) -> CGPoint {
            CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)), y: center.y + radius * CGFloat(sin(angle.radians)))
        }

        var path = Path()
        path.move(to: pt(r * innerFrac, start))
        path.addLine(to: pt(r * outerFrac, start))
        path.addArc(center: center, radius: r * outerFrac, startAngle: start, endAngle: end, clockwise: false)
        path.addLine(to: pt(r * innerFrac, end))
        path.addArc(center: center, radius: r * innerFrac, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

/// A brief glowing highlight over the segment/ring (or bull) that was just
/// hit — flashes in, then fades out on its own.
private struct FlashHighlight: View {
    let dart: Dart
    let r: CGFloat

    @State private var glow = false

    var body: some View {
        Group {
            if dart.isBull {
                let frac: CGFloat = dart.multiplier == .double ? 0.05 : 0.13
                Circle()
                    .fill(dart.multiplier.color.opacity(glow ? 0.6 : 0))
                    .frame(width: r * frac * 2.4, height: r * frac * 2.4)
            } else if !dart.isMiss, let index = Dartboard.segmentOrder.firstIndex(of: dart.value) {
                let fracs = ringFractions(for: dart.multiplier)
                WedgeShape(index: index, innerFrac: fracs.0, outerFrac: fracs.1)
                    .fill(dart.multiplier.color.opacity(glow ? 0.55 : 0))
                    .frame(width: r * 2, height: r * 2)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) { glow = true }
            withAnimation(.easeIn(duration: 0.55).delay(0.25)) { glow = false }
        }
    }

    private func ringFractions(for multiplier: Multiplier) -> (CGFloat, CGFloat) {
        switch multiplier {
        case .single: return (0.13, 0.80)
        case .double: return (0.80, 0.88)
        case .triple: return (0.48, 0.58)
        }
    }
}

/// A small dot marking where a thrown dart landed, dropping in with a spring.
/// Position is deterministic per-dart (seeded by its UUID) so re-renders
/// don't jitter the marker around.
struct DartMarker: View {
    let dart: Dart
    let center: CGPoint
    let r: CGFloat

    @State private var appeared = false

    var body: some View {
        Circle()
            .fill(dart.isMiss ? Theme.textTertiary : dart.multiplier.color)
            .frame(width: max(8, r * 0.07), height: max(8, r * 0.07))
            .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            .scaleEffect(appeared ? 1 : 2.6)
            .opacity(appeared ? 1 : 0)
            .position(position())
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                    appeared = true
                }
            }
    }

    private func position() -> CGPoint {
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(dart.id.hashValue)))

        if dart.isMiss {
            let angle = Angle.degrees(Double.random(in: 0..<360, using: &rng))
            let radius = r * 0.97
            return CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)), y: center.y + radius * CGFloat(sin(angle.radians)))
        }

        if dart.isBull {
            let radius = r * (dart.multiplier == .double ? 0.03 : 0.085)
            let angle = Angle.degrees(Double.random(in: 0..<360, using: &rng))
            return CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)), y: center.y + radius * CGFloat(sin(angle.radians)))
        }

        let index = Dartboard.segmentOrder.firstIndex(of: dart.value) ?? 0
        let baseAngle = -90.0 + Double(index) * 18.0
        let angleDeg = baseAngle + Double.random(in: -7...7, using: &rng)

        let radiusFrac: Double
        switch dart.multiplier {
        case .single: radiusFrac = Double.random(in: 0.63...0.76, using: &rng)
        case .double: radiusFrac = 0.84
        case .triple: radiusFrac = 0.53
        }

        let angle = Angle.degrees(angleDeg)
        let radius = r * radiusFrac
        return CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)), y: center.y + radius * CGFloat(sin(angle.radians)))
    }
}
