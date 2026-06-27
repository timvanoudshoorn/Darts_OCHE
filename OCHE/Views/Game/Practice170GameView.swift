import SwiftUI

/// 170 Practice (WDA drill): a shared running score starting at 170, players
/// take turns trying to check it out. Tracks rounds finished per player.
struct Practice170GameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: Practice170Engine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false

    private let accent = GameMode.practice170.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .practice170,
                    players: engine.players,
                    winnerIndex: nil,
                    dartLog: engine.dartLog,
                    extraInfo: { i in "\(engine.roundsFinished(for: i)) finished" },
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
                    title: "170 Practice",
                    accent: accent,
                    canUndo: engine.canUndo,
                    onUndo: { engine.undo() },
                    onSettings: { showSettings = true },
                    onQuit: { endSession() }
                )

                VStack(spacing: 8) {
                    Text("SCORE REMAINING")
                        .font(OcheFont.label(13))
                        .foregroundStyle(Theme.textSecondary)

                    Text("\(engine.sharedScore)")
                        .font(OcheFont.scoreDisplay(72))
                        .foregroundStyle(engine.sharedScore > 170 ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.scoreCardColor(forRemaining: engine.sharedScore)))
                        .contentTransition(.numericText())
                        .animation(.default, value: engine.sharedScore)

                    Text(engine.currentPlayer.name.uppercased())
                        .font(OcheFont.label(14))
                        .foregroundStyle(Theme.textSecondary)

                    if !engine.checkoutSuggestions.isEmpty {
                        CheckoutSuggestionList(suggestions: engine.checkoutSuggestions, color: Theme.magenta)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xl)
                .cardStyle(cornerRadius: Corner.xl)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(engine.players.indices, id: \.self) { i in
                            TotalScoreCard(
                                playerName: engine.players[i].name,
                                total: engine.roundsFinished(for: i),
                                isActive: i == engine.currentPlayerIndex,
                                accent: accent,
                                subtitle: "Finished"
                            )
                            .frame(width: 160)
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

    private func cellState(_ dart: Dart) -> NumberPadCellState {
        let resulting = engine.sharedScore - dart.points
        if resulting == 0, dart.isDouble { return .checkout }
        if resulting < 0 || resulting == 1 || (resulting == 0 && !dart.isDouble) { return .bust }
        if resulting > 0, resulting <= 40, CheckoutTable.isCheckoutPossible(resulting) { return .near }
        return .normal
    }

    private func handleThrow(_ dart: Dart) {
        let outcome = engine.throwDart(dart)

        switch outcome {
        case .bust:
            popup = .bust()
            flashColor = Theme.bust
            HapticManager.shared.bust()
            SoundManager.shared.play(.bust)

        case .checkout:
            popup = .checkout()
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)

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

    private func endSession() {
        engine.endSession()
        showGameOver = true
    }
}
