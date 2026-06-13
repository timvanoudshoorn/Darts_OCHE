import SwiftUI

/// Around the Clock: race through a sequence of targets.
struct AroundClockGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: AroundClockEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false

    private let accent = GameMode.aroundTheClock.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .aroundTheClock,
                    players: engine.players,
                    winnerIndex: engine.winnerIndex,
                    dartLog: engine.dartLog,
                    extraInfo: { i in targetLabel(for: i) },
                    config: config
                )
            } else {
                gameBody
            }
        }
    }

    private var gameBody: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 16) {
                GameTopBar(
                    title: "Around the Clock",
                    accent: accent,
                    canUndo: engine.canUndo,
                    onUndo: { engine.undo() },
                    onSettings: { showSettings = true },
                    onQuit: { dismiss() }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(engine.players.indices, id: \.self) { i in
                            ProgressCard(
                                playerName: engine.players[i].name,
                                targetLabel: shortTargetLabel(for: i),
                                progress: engine.progress[i],
                                total: engine.sequence.count,
                                isActive: i == engine.currentPlayerIndex,
                                accent: accent
                            )
                            .frame(width: 180)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Text(statusLabel)
                    .font(OcheFont.heading(20))
                    .foregroundStyle(Theme.accentGradient)

                Dartboard(
                    hits: engine.currentTurnDarts,
                    completedSegments: completedSegments,
                    targetSegment: engine.currentTarget(for: engine.currentPlayerIndex)
                )
                .frame(maxHeight: 220)
                .padding(.vertical, 4)

                DartsThisTurnView(darts: engine.currentTurnDarts, accent: accent)

                Spacer(minLength: 0)

                if engine.multipliersCount {
                    NumberPad(multiplier: $multiplier, accent: accent, stateFor: cellState, onThrow: handleThrow)
                } else {
                    simplePad
                }
            }
            .padding(16)
            .padding(.bottom, 8)
        }
        .popupOverlay($popup, settings: settings)
        .screenFlash($flashColor, settings: settings)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showSettings) { SettingsSheet() }
    }

    private func targetLabel(for player: Int) -> String {
        if let target = engine.currentTarget(for: player) {
            return target == 25 ? "Target: Bull" : "Target: \(target)"
        }
        return "Finished!"
    }

    private func shortTargetLabel(for player: Int) -> String {
        if let target = engine.currentTarget(for: player) {
            return target == 25 ? "🎯" : "\(target)"
        }
        return "✓"
    }

    /// "Aim for: [number]" / "Aim for: BULL" status text for the active player.
    private var statusLabel: String {
        if let target = engine.currentTarget(for: engine.currentPlayerIndex) {
            return target == 25 ? "AIM FOR: BULL" : "AIM FOR: \(target)"
        }
        return "FINISHED!"
    }

    /// Segments the active player has already completed, for the dartboard overlay.
    private var completedSegments: Set<Int> {
        let p = engine.currentPlayerIndex
        let done = engine.progress[p]
        guard done > 0 else { return [] }
        return Set(engine.sequence[0..<done])
    }

    private func cellState(_ dart: Dart) -> NumberPadCellState {
        engine.isOnTarget(dart) ? .target : .normal
    }

    /// Simplified Hit/Miss pad used when multipliers don't advance progress.
    private var simplePad: some View {
        HStack(spacing: 8) {
            Button {
                let target = engine.currentTarget(for: engine.currentPlayerIndex) ?? 0
                handleThrow(Dart(value: target, multiplier: .single))
            } label: {
                Text("HIT ✓")
                    .font(OcheFont.button(26))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.green.opacity(0.22)))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.green, lineWidth: 2))
                    .foregroundStyle(Theme.green)
            }
            .buttonStyle(SquashButtonStyle())
            .frame(maxWidth: .infinity)
            .layoutPriority(2)

            Button {
                handleThrow(Dart.miss)
            } label: {
                Text("MISS")
                    .font(OcheFont.button(22))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.stroke, lineWidth: 1))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(SquashButtonStyle())
            .frame(maxWidth: .infinity)
        }
    }

    private func handleThrow(_ dart: Dart) {
        let wasOnTarget = engine.isOnTarget(dart)
        let playerName = engine.currentPlayer.name
        let previousPlayerIndex = engine.currentPlayerIndex

        let finished = engine.throwDart(dart)

        if finished {
            popup = .gameOver(winner: playerName)
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }
        } else if wasOnTarget {
            popup = PopupEvent(title: dart.fullLabel, subtitle: "Nice hit!", icon: "checkmark.circle.fill", kind: .success, color: accent)
            HapticManager.shared.bigHit()
            SoundManager.shared.play(.doubleHit)
            if engine.currentPlayerIndex != previousPlayerIndex {
                // Turn ended on the same dart that hit — let the hit popup show.
            }
        } else if engine.currentPlayerIndex != previousPlayerIndex {
            popup = .turnDone(next: engine.currentPlayer.name)
            HapticManager.shared.turnAdvance()
            SoundManager.shared.play(.turnAdvance)
        } else {
            HapticManager.shared.dartThrown()
            SoundManager.shared.play(.dartHit)
        }
    }
}

/// Generic "progress toward a target" score card, used by Around the Clock.
struct ProgressCard: View {
    var playerName: String
    var targetLabel: String
    var progress: Int
    var total: Int
    var isActive: Bool
    var accent: Color

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
            }

            Text(targetLabel)
                .font(OcheFont.scoreDisplay(isActive ? 40 : 30))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            ProgressView(value: Double(progress), total: Double(total))
                .tint(accent)

            Text("\(progress) / \(total)")
                .font(OcheFont.body(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(isActive ? accent.opacity(0.5) : Theme.stroke, lineWidth: isActive ? 2 : 1)
        )
        .shadow(color: isActive ? accent.opacity(0.25) : .clear, radius: 16)
    }
}
