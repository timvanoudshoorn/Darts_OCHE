import SwiftUI

/// Shanghai: each round targets a number 1...N; hit S+D+T of it in one visit
/// for an instant win, otherwise highest total after all rounds wins.
struct ShanghaiGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: ShanghaiEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false
    @State private var winnerNote: String? = nil

    private let accent = GameMode.shanghai.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .shanghai,
                    players: engine.players,
                    winnerIndex: engine.winnerIndex,
                    dartLog: engine.dartLog,
                    extraInfo: { i in "\(engine.scores[i]) pts" },
                    winnerNote: winnerNote,
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
                    title: "Target: \(targetLabel)",
                    accent: accent,
                    canUndo: engine.canUndo,
                    onUndo: { engine.undo() },
                    onSettings: { showSettings = true },
                    onQuit: { dismiss() }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(engine.players.indices, id: \.self) { i in
                            TotalScoreCard(
                                playerName: engine.players[i].name,
                                total: engine.scores[i],
                                isActive: i == engine.currentPlayerIndex,
                                accent: accent
                            )
                            .frame(width: 180)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Text("Round \(min(engine.currentRound + 1, engine.totalRounds)) of \(engine.totalRounds) — Shanghai (S+D+T of \(targetLabel)) wins instantly")
                    .font(OcheFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

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

    private var targetLabel: String {
        engine.target == 25 ? "Bull" : "\(engine.target)"
    }

    private func cellState(_ dart: Dart) -> NumberPadCellState {
        dart.value == engine.target && dart.points > 0 ? .target : .normal
    }

    private func handleThrow(_ dart: Dart) {
        let previousPlayerIndex = engine.currentPlayerIndex
        let targetBeforeThrow = engine.target
        let outcome = engine.throwDart(dart)

        switch outcome {
        case .shanghaiWin:
            winnerNote = "Shanghai! (S + D + T of \(targetLabel))"
            popup = .gameOver(winner: engine.currentPlayer.name)
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }

        case .roundsComplete:
            let winnerName = engine.winnerIndex.map { engine.players[$0].name } ?? ""
            popup = .gameOver(winner: winnerName)
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }

        case .normal:
            if dart.value == targetBeforeThrow, dart.points > 0 {
                popup = .dartHit(dart, accent: accent)
                HapticManager.shared.bigHit()
                SoundManager.shared.play(dart.multiplier == .triple ? .tripleHit : .doubleHit)
            } else {
                HapticManager.shared.dartThrown()
                SoundManager.shared.play(.dartHit)
            }

            if engine.currentPlayerIndex != previousPlayerIndex {
                popup = .turnDone(next: engine.currentPlayer.name)
                HapticManager.shared.turnAdvance()
                SoundManager.shared.play(.turnAdvance)
            }
        }
    }
}
