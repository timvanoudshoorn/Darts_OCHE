import SwiftUI

/// "Throw for the bull" — before a match, each player taps the board near the
/// bullseye to mark where their dart landed. Whoever lands closest to center
/// throws first; the player order is reordered accordingly before the match
/// begins.
struct ThrowForBullView: View {
    let mode: GameMode
    @State var config: GameLaunchConfig

    @EnvironmentObject private var router: AppRouter

    @State private var currentIndex = 0
    @State private var tapFraction: CGPoint? = nil
    @State private var pendingDistance: CGFloat? = nil
    @State private var distances: [CGFloat] = []
    @State private var showResults = false

    private var players: [GamePlayer] { config.players }
    private var isLastPlayer: Bool { currentIndex == players.count - 1 }

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("THROW FOR THE BULL")
                        .font(OcheFont.heading(26))
                        .foregroundStyle(mode.accentColor)

                    if showResults {
                        Text("Closest to the bull throws first")
                            .font(OcheFont.body(14))
                            .foregroundStyle(Theme.textSecondary)
                    } else if pendingDistance != nil {
                        Text("Tap again to adjust, or confirm below")
                            .font(OcheFont.body(15))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("\(players[currentIndex].name): tap where your dart landed")
                            .font(OcheFont.body(15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.top, 24)

                GeometryReader { geo in
                    let size = min(geo.size.width, geo.size.height)
                    let r = size / 2
                    let center = CGPoint(x: r, y: r)

                    ZStack {
                        Dartboard()
                            .frame(width: size, height: size)

                        if showResults {
                            ForEach(players.indices, id: \.self) { i in
                                let point = pointFor(distance: distances[i], index: i, center: center, r: r)
                                ResultMarker(
                                    label: "\(i + 1)",
                                    color: i == 0 ? Theme.scoreCheckout : Theme.textSecondary
                                )
                                .position(point)
                            }
                        } else if let tapFraction {
                            ResultMarker(label: "\(currentIndex + 1)", color: mode.accentColor)
                                .position(tapFraction)
                        }
                    }
                    .frame(width: size, height: size)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                guard !showResults else { return }
                                mark(location: value.location, center: center, r: r, fullSize: geo.size)
                            }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: 360)
                .padding(.horizontal, 24)

                if showResults {
                    VStack(spacing: 10) {
                        ForEach(orderedIndices, id: \.self) { i in
                            HStack {
                                Text(i == orderedIndices.first ? "🎯" : "")
                                    .frame(width: 24)
                                Text(players[i].name.uppercased())
                                    .font(OcheFont.heading(18))
                                    .foregroundStyle(i == orderedIndices.first ? mode.accentColor : Theme.textPrimary)
                                Spacer()
                                Text(String(format: "%.0f%% from center", (1 - distances[i]) * 100))
                                    .font(OcheFont.body(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Corner.md).fill(Theme.surface))
                            .woodFrame(cornerRadius: Corner.md, lineWidth: 1.5)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)

                    Button {
                        config.players = orderedIndices.map { players[$0] }
                        router.path.removeLast()
                        router.path.append(Route.play(mode, config))
                    } label: {
                        Text("START MATCH")
                            .font(OcheFont.heading(20))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                            .background(RoundedRectangle(cornerRadius: Corner.xl).fill(mode.accentColor))
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(SquashButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                } else {
                    Spacer(minLength: 0)

                    if pendingDistance != nil {
                        Button {
                            confirmThrow()
                        } label: {
                            Text("CONFIRM")
                                .font(OcheFont.heading(18))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.lg)
                                .background(RoundedRectangle(cornerRadius: Corner.xl).fill(mode.accentColor))
                                .foregroundStyle(Color.black)
                        }
                        .buttonStyle(SquashButtonStyle())
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxxl)
                    } else {
                        Text("Player \(currentIndex + 1) of \(players.count)")
                            .font(OcheFont.label(13))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var orderedIndices: [Int] {
        players.indices.sorted { distances[$0] < distances[$1] }
    }

    /// Places (or moves) the tap marker without committing it — the player
    /// can tap again to adjust before confirming, so an accidental tap
    /// doesn't lock in a wrong throw.
    private func mark(location: CGPoint, center: CGPoint, r: CGFloat, fullSize: CGSize) {
        // `location` is relative to the GeometryReader, which may be larger
        // than the square board — translate into board-local coordinates.
        let boardOrigin = CGPoint(x: (fullSize.width - r * 2) / 2, y: (fullSize.height - r * 2) / 2)
        let local = CGPoint(x: location.x - boardOrigin.x, y: location.y - boardOrigin.y)
        let dx = local.x - center.x
        let dy = local.y - center.y
        let distance = min(1, sqrt(dx * dx + dy * dy) / r)

        tapFraction = local
        pendingDistance = distance
        HapticManager.shared.dartThrown()
        SoundManager.shared.play(.dartHit)
    }

    /// Commits the currently-marked tap as this player's throw and advances.
    private func confirmThrow() {
        guard let pendingDistance else { return }
        distances.append(pendingDistance)
        self.pendingDistance = nil

        if isLastPlayer {
            withAnimation(Motion.settle) {
                showResults = true
            }
        } else {
            currentIndex += 1
            tapFraction = nil
        }
    }

    private func pointFor(distance: CGFloat, index: Int, center: CGPoint, r: CGFloat) -> CGPoint {
        // Results screen: fan the recorded throws out at their recorded
        // distance from center at evenly-spaced angles for legibility.
        let angle = Angle.degrees(-90 + Double(index) * (360.0 / Double(max(players.count, 1))))
        let radius = distance * r
        return CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)), y: center.y + radius * CGFloat(sin(angle.radians)))
    }
}

/// A small numbered marker dot dropped onto the board.
private struct ResultMarker: View {
    let label: String
    let color: Color

    @State private var appeared = false

    var body: some View {
        ZStack {
            Circle().fill(color)
            Text(label)
                .font(OcheFont.bodyBold(11))
                .foregroundStyle(Color.black)
        }
        .frame(width: 22, height: 22)
        .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
        .scaleEffect(appeared ? 1 : 2.4)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(Motion.tap) {
                appeared = true
            }
        }
    }
}
