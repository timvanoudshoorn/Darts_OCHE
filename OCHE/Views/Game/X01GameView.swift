import SwiftUI

/// Standard Darts (301/501), double-out.
struct X01GameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: X01Engine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false
    @State private var flashDart: Dart? = nil
    @State private var showConfetti = false

    private let accent = GameMode.standard.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .standard,
                    players: engine.players,
                    winnerIndex: engine.winnerIndex,
                    dartLog: engine.dartLog,
                    extraInfo: { i in "\(engine.remaining(for: i)) left" },
                    onPlayAgain: nil,
                    onHome: nil,
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
                    title: "\(engine.current.startingScore)",
                    accent: accent,
                    canUndo: engine.canUndo,
                    onUndo: { engine.undo() },
                    onSettings: { showSettings = true },
                    onQuit: { dismiss() }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(engine.players.indices, id: \.self) { i in
                            ScoreCard(
                                playerName: engine.players[i].name,
                                remaining: engine.remaining(for: i),
                                isActive: i == engine.currentPlayerIndex,
                                accent: accent
                            )
                            .frame(width: 180)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let suggestion = engine.checkoutSuggestion {
                    HStack(spacing: 6) {
                        Text("CHECKOUT:")
                            .font(OcheFont.label(12))
                            .foregroundStyle(Theme.textTertiary)
                        Text(suggestion.labels.joined(separator: "  ·  "))
                            .font(OcheFont.bodyBold(15))
                            .foregroundStyle(Theme.scoreCheckout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Dartboard(hits: engine.currentTurnDarts, flashDart: flashDart)
                    .frame(maxHeight: 220)
                    .padding(.vertical, 4)

                DartsThisTurnView(darts: engine.currentTurnDarts, accent: accent)

                Spacer(minLength: 0)

                NumberPad(multiplier: $multiplier, accent: accent, stateFor: cellState, onThrow: handleThrow)
            }
            .padding(16)
            .padding(.bottom, 8)

            if showConfetti {
                ConfettiBurst()
            }
        }
        .popupOverlay($popup, settings: settings)
        .screenFlash($flashColor, settings: settings)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showSettings) { SettingsSheet() }
    }

    private func cellState(_ dart: Dart) -> NumberPadCellState {
        if engine.wouldCheckout(dart) { return .checkout }
        if engine.wouldBust(dart) { return .bust }
        let resulting = engine.remaining(for: engine.currentPlayerIndex) - dart.points
        if resulting > 0, resulting <= 40, CheckoutTable.isCheckoutPossible(resulting) {
            return .near
        }
        return .normal
    }

    private func handleThrow(_ dart: Dart) {
        let playerName = engine.currentPlayer.name
        let outcome = engine.throwDart(dart)
        flashDart = dart

        switch outcome {
        case .bust:
            popup = .bust()
            flashColor = Theme.bust
            HapticManager.shared.bust()
            SoundManager.shared.play(.bust)

        case .checkout:
            popup = .gameOver(winner: playerName)
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            withAnimation { showConfetti = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }

        case .turnComplete:
            popup = .turnDone(next: engine.currentPlayer.name)
            HapticManager.shared.turnAdvance()
            SoundManager.shared.play(.turnAdvance)

        case .normal:
            if dart.multiplier != .single || dart.isBull {
                popup = .dartHit(dart, accent: accent)
                if dart.multiplier == .triple { flashColor = Theme.triple.opacity(0.6) }
                HapticManager.shared.bigHit()
                SoundManager.shared.play(dart.multiplier == .triple ? .tripleHit : (dart.isBull ? .bullHit : .doubleHit))
            } else {
                HapticManager.shared.dartThrown()
                SoundManager.shared.play(.dartHit)
            }
        }
    }
}
