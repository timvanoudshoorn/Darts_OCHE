import SwiftUI

/// Around the Clock: race through a sequence of targets.
struct AroundClockGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: AroundClockEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

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

                targetPad
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

    /// Always exactly 4 buttons: Single/Double/Triple of the *current target*
    /// + Miss — never the full 20-number grid, since only the active target
    /// is ever a relevant throw in this mode. `engine.multipliersCount` is a
    /// pure scoring rule now (how far a multiplier-hit advances), not a pad
    /// selector — every multiplier is always offered here regardless of it.
    @ViewBuilder
    private var targetPad: some View {
        // Defensive fallback for the brief nil-target window between a
        // player's final hit and the game-over transition firing — mirrors
        // the old simplePad's `?? 0` behavior rather than force-unwrapping.
        let target = engine.currentTarget(for: engine.currentPlayerIndex) ?? 0

        VStack(spacing: 8) {
            if target == 25 {
                // Bull only ever supports Single/Double on a real board —
                // `Dart.init` silently downgrades triple-bull to double, so
                // looping the generic multiplier list here would render a
                // second, duplicate double-bull button. Two explicit
                // buttons avoids that entirely.
                HStack(spacing: 8) {
                    bullButton(.single, label: "BULL")
                    bullButton(.double, label: "D-BULL")
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(Multiplier.allCases) { mult in
                        targetButton(target, mult)
                    }
                }
            }

            NumberPadButton(dart: Dart.miss, state: .normal, accent: accent, customLabel: "MISS") {
                handleThrow(Dart.miss)
            }
        }
    }

    private func targetButton(_ target: Int, _ mult: Multiplier) -> some View {
        let dart = Dart(value: target, multiplier: mult)
        return NumberPadButton(dart: dart, state: cellState(dart), accent: accent) {
            handleThrow(dart)
        }
        .frame(maxWidth: .infinity)
    }

    private func bullButton(_ mult: Multiplier, label: String) -> some View {
        let dart = Dart(value: 25, multiplier: mult)
        return NumberPadButton(dart: dart, state: cellState(dart), accent: accent, customLabel: label) {
            handleThrow(dart)
        }
        .frame(maxWidth: .infinity)
    }

    private func cellState(_ dart: Dart) -> NumberPadCellState {
        engine.isOnTarget(dart) ? .target : .normal
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
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: Corner.xl, isHighlighted: isActive, highlightColor: accent)
        .shadow(color: isActive ? accent.opacity(0.25) : .clear, radius: 16)
    }
}
