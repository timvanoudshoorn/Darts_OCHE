import SwiftUI

/// Halve-It: score against each round's target or your total is halved.
struct HalveItGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: HalveItEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false

    private let accent = GameMode.halveIt.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .halveIt,
                    players: engine.players,
                    winnerIndex: engine.winnerIndex,
                    dartLog: engine.dartLog,
                    extraInfo: { i in "\(engine.scores[i]) pts" },
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
                    title: "Halve-It",
                    accent: accent,
                    canUndo: engine.canUndo,
                    onUndo: { engine.undo() },
                    onSettings: { showSettings = true },
                    onQuit: { dismiss() }
                )

                VStack(spacing: 4) {
                    Text("ROUND \(min(engine.currentRound + 1, engine.targets.count)) OF \(engine.targets.count) · TARGET")
                        .font(OcheFont.label(13))
                        .foregroundStyle(Theme.textSecondary)

                    Text(engine.currentTarget.label.uppercased())
                        .font(OcheFont.scoreDisplay(64))
                        .foregroundStyle(Theme.modeHalveIt)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    if hitThisTurn {
                        Text("✓ HIT! KEEP SCORING")
                            .font(OcheFont.label(13))
                            .foregroundStyle(Theme.green)
                    } else {
                        Text("⚠ MISS ALL 3 → SCORE HALVES")
                            .font(OcheFont.label(13))
                            .foregroundStyle(Theme.modeHalveIt)
                    }
                }
                .frame(maxWidth: .infinity)

                if engine.players.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(engine.players.indices, id: \.self) { i in
                                TotalScoreCard(
                                    playerName: engine.players[i].name,
                                    total: engine.scores[i],
                                    isActive: i == engine.currentPlayerIndex,
                                    accent: accent
                                )
                                .frame(width: 140)
                            }
                        }
                        .padding(.vertical, 4)
                    }
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

    /// Whether any dart thrown so far this turn matches the current target.
    private var hitThisTurn: Bool {
        engine.currentTurnDarts.contains { cellState($0) == .target }
    }

    private func cellState(_ dart: Dart) -> NumberPadCellState {
        guard dart.points > 0 else { return .normal }
        switch engine.currentTarget {
        case .number(let n):
            return dart.value == n ? .target : .normal
        case .anyDouble:
            return dart.isDouble ? .target : .normal
        case .anyTriple:
            return dart.multiplier == .triple ? .target : .normal
        }
    }

    private func handleThrow(_ dart: Dart) {
        let scores = cellState(dart) == .target

        let outcome = engine.throwDart(dart)

        switch outcome {
        case .gameOver:
            let winnerName = engine.winnerIndex.map { engine.players[$0].name } ?? ""
            popup = .gameOver(winner: winnerName)
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }

        case .roundScored(let points):
            popup = PopupEvent(title: "+\(points)", subtitle: "Scored on \(engine.targets[engine.currentRound - 1].label)", icon: "checkmark.circle.fill", kind: .success, color: accent)
            HapticManager.shared.bigHit()
            SoundManager.shared.play(.doubleHit)

        case .halved(let newScore):
            popup = .halved(newScore: newScore)
            flashColor = Theme.bust
            HapticManager.shared.bust()
            SoundManager.shared.play(.bust)

        case .normal:
            if scores {
                popup = .dartHit(dart, accent: accent)
                HapticManager.shared.bigHit()
                SoundManager.shared.play(dart.multiplier == .triple ? .tripleHit : .doubleHit)
            } else {
                HapticManager.shared.dartThrown()
                SoundManager.shared.play(.dartHit)
            }
        }
    }
}
