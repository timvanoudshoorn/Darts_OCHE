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
                                targetLabel: targetLabel(for: i),
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

                DartsThisTurnView(darts: engine.currentTurnDarts, accent: accent)

                Spacer(minLength: 0)

                NumberPad(multiplier: $multiplier, accent: accent, stateFor: cellState, onThrow: handleThrow)
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
