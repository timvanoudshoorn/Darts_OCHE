import SwiftUI

/// Count-Up: everyone throws the same number of rounds, highest total wins.
struct CountUpGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: CountUpEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false

    private let accent = GameMode.countUp.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .countUp,
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
                    title: "Round \(min(engine.currentRound + 1, engine.totalRounds)) / \(engine.totalRounds)",
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

                DartsThisTurnView(darts: engine.currentTurnDarts, accent: accent)

                Spacer(minLength: 0)

                NumberPad(multiplier: $multiplier, accent: accent, stateFor: { _ in .normal }, onThrow: handleThrow)
            }
            .padding(16)
            .padding(.bottom, 8)
        }
        .popupOverlay($popup, settings: settings)
        .screenFlash($flashColor, settings: settings)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showSettings) { SettingsSheet() }
    }

    private func handleThrow(_ dart: Dart) {
        let previousPlayerIndex = engine.currentPlayerIndex
        let gameEnded = engine.throwDart(dart)

        if gameEnded {
            let winnerName = engine.winnerIndex.map { engine.players[$0].name }
            popup = .gameOver(winner: winnerName ?? "")
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }
            return
        }

        if dart.multiplier != .single || dart.isBull {
            popup = .dartHit(dart, accent: accent)
            if dart.multiplier == .triple { flashColor = Theme.triple.opacity(0.6) }
            HapticManager.shared.bigHit()
            SoundManager.shared.play(dart.multiplier == .triple ? .tripleHit : (dart.isBull ? .bullHit : .doubleHit))
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

/// Simple cumulative-total score card, used by Count-Up and Shanghai.
struct TotalScoreCard: View {
    var playerName: String
    var total: Int
    var isActive: Bool
    var accent: Color
    var subtitle: String? = nil

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

            Text("\(total)")
                .font(OcheFont.scoreDisplay(isActive ? 48 : 34))
                .foregroundStyle(Theme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(OcheFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
            }
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
