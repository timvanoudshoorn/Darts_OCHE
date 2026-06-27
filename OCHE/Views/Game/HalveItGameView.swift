import SwiftUI

/// Halve-It: score against each round's target or your total is halved.
struct HalveItGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: HalveItEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

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

    /// Whether any dart thrown so far this turn matches the current target.
    private var hitThisTurn: Bool {
        engine.currentTurnDarts.contains { cellState($0) == .target }
    }

    /// Only what's relevant to *this round's* target — never the full grid
    /// with an open multiplier choice, since only one multiplier (or one
    /// exact number) ever actually scores per round.
    @ViewBuilder
    private var targetPad: some View {
        switch engine.currentTarget {
        case .number(25):
            // Bull only ever supports Single/Double on a real board — no
            // triple-bull button (Dart.init silently downgrades any attempt
            // to double, so a "T-Bull" button would be a lie).
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    bullButton(.single, label: "BULL")
                    bullButton(.double, label: "D-BULL")
                }
                missButton
            }

        case .number(let n):
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Multiplier.allCases) { mult in
                        numberButton(n, mult)
                    }
                }
                missButton
            }

        case .anyDouble:
            // Any double anywhere on the board scores — including double
            // bull, which genuinely is a double. Locking the multiplier
            // means no selector is shown; every button is already a double.
            VStack(spacing: 8) {
                lockedGrid(.double, includeBull: true)
                missButton
            }

        case .anyTriple:
            // Triple bull can't exist (Dart.init downgrades it to double),
            // so bull is omitted entirely rather than shown mislabeled.
            VStack(spacing: 8) {
                lockedGrid(.triple, includeBull: false)
                missButton
            }
        }
    }

    private func numberButton(_ n: Int, _ mult: Multiplier) -> some View {
        let dart = Dart(value: n, multiplier: mult)
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

    private var missButton: some View {
        NumberPadButton(dart: Dart.miss, state: .normal, accent: accent, customLabel: "MISS") {
            handleThrow(Dart.miss)
        }
    }

    private let lockedColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private func lockedGrid(_ mult: Multiplier, includeBull: Bool) -> some View {
        LazyVGrid(columns: lockedColumns, spacing: 8) {
            ForEach(Array((1...20).reversed()), id: \.self) { n in
                let dart = Dart(value: n, multiplier: mult)
                NumberPadButton(dart: dart, state: cellState(dart), accent: accent) {
                    handleThrow(dart)
                }
            }
            if includeBull {
                let dart = Dart(value: 25, multiplier: mult)
                NumberPadButton(dart: dart, state: cellState(dart), accent: accent, customLabel: "D-BULL") {
                    handleThrow(dart)
                }
            }
        }
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
