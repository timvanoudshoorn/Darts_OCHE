import SwiftUI

/// Cricket: close 20-15 + Bull, score on open numbers.
struct CricketGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: CricketEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false

    private let accent = GameMode.cricket.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .cricket,
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
                    title: "Cricket",
                    accent: accent,
                    canUndo: engine.canUndo,
                    onUndo: { engine.undo() },
                    onSettings: { showSettings = true },
                    onQuit: { dismiss() }
                )

                CricketBoard(engine: engine, accent: accent)

                HStack(spacing: 8) {
                    Circle().fill(accent).frame(width: 8, height: 8)
                    Text("\(engine.currentPlayer.name.uppercased())'S TURN")
                        .font(OcheFont.label(13))
                        .foregroundStyle(Theme.textSecondary)
                }
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

    private func cellState(_ dart: Dart) -> NumberPadCellState {
        guard CricketState.numbers.contains(dart.value), dart.points > 0 else { return .normal }
        let p = engine.currentPlayerIndex
        return engine.marks(player: p, number: dart.value) < 3 ? .target : .normal
    }

    private func handleThrow(_ dart: Dart) {
        let playerName = engine.currentPlayer.name
        let willScore = engine.wouldScore(dart)
        let previousPlayerIndex = engine.currentPlayerIndex

        let won = engine.throwDart(dart)

        if won {
            popup = .gameOver(winner: playerName)
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }
            return
        }

        if CricketState.numbers.contains(dart.value), dart.points > 0 {
            if willScore {
                popup = PopupEvent(title: dart.fullLabel, subtitle: "Scored!", icon: "target", kind: .success, color: accent)
            } else {
                popup = PopupEvent(title: dart.fullLabel, subtitle: "Mark", icon: "circle.fill", kind: .info, color: accent)
            }
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

/// The classic Cricket scoreboard grid: numbers down the side, players across
/// the top, marks shown as slash/cross/circle.
struct CricketBoard: View {
    @ObservedObject var engine: CricketEngine
    var accent: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("")
                    .frame(width: 44)
                ForEach(engine.players.indices, id: \.self) { i in
                    let isActive = i == engine.currentPlayerIndex
                    VStack(spacing: 2) {
                        Text(engine.players[i].name.uppercased())
                            .font(OcheFont.label(11))
                            .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("\(engine.scores[i])")
                            .font(OcheFont.heading(20))
                            .foregroundStyle(isActive ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.textPrimary))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isActive ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Color.clear))
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            ForEach(CricketState.numbers, id: \.self) { number in
                HStack {
                    Text(number == 25 ? "B" : "\(number)")
                        .font(OcheFont.heading(18))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 44)

                    ForEach(engine.players.indices, id: \.self) { i in
                        MarkSymbol(marks: engine.marks(player: i, number: number), accent: accent)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

/// 0 marks = empty, 1 = slash, 2 = X, 3 = circled X (closed).
struct MarkSymbol: View {
    var marks: Int
    var accent: Color

    var body: some View {
        ZStack {
            if marks >= 3 {
                Circle()
                    .strokeBorder(accent, lineWidth: 2)
                    .frame(width: 26, height: 26)
            }
            if marks >= 1 {
                Image(systemName: marks >= 2 ? "xmark" : "line.diagonal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(marks >= 3 ? accent : Theme.textPrimary)
            } else {
                Text("–")
                    .font(OcheFont.body(14))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(height: 30)
    }
}
