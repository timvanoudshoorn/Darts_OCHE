import SwiftUI

/// Killer: bull-off to claim a number, go live, then hunt opponents' lives.
struct KillerGameView: View {
    let config: GameLaunchConfig
    @StateObject var engine: KillerEngine
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var multiplier: Multiplier = .single
    @State private var popup: PopupEvent? = nil
    @State private var flashColor: Color? = nil
    @State private var showSettings = false
    @State private var showGameOver = false

    private let accent = GameMode.killer.accentColor

    var body: some View {
        Group {
            if showGameOver {
                GameOverView(
                    mode: .killer,
                    players: engine.players,
                    winnerIndex: engine.winnerIndex,
                    dartLog: engine.dartLog,
                    extraInfo: { i in "\(engine.lives(for: i)) lives" },
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
                    title: engine.phase == .assignment ? "Bull-Off" : "Killer",
                    accent: accent,
                    canUndo: engine.canUndo,
                    onUndo: { engine.undo() },
                    onSettings: { showSettings = true },
                    onQuit: { dismiss() }
                )

                if engine.phase == .assignment {
                    Text("\(engine.currentPlayer.name): throw to claim your number")
                        .font(OcheFont.body(14))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(engine.players.indices, id: \.self) { i in
                            KillerCard(
                                playerName: engine.players[i].name,
                                number: engine.assignedNumber(for: i),
                                marks: engine.marks(for: i),
                                isLive: engine.isLive(i),
                                lives: engine.lives(for: i),
                                isActive: i == engine.currentPlayerIndex,
                                accent: accent
                            )
                            .frame(width: 150)
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
        guard dart.points > 0 else { return .normal }

        if engine.phase == .assignment {
            if dart.value >= 1, dart.value <= 20,
               !engine.players.indices.contains(where: { engine.assignedNumber(for: $0) == dart.value }) {
                return .target
            }
            return .normal
        }

        let p = engine.currentPlayerIndex
        guard dart.value >= 1, dart.value <= 20 else { return .normal }

        if engine.assignedNumber(for: p) == dart.value {
            return engine.isLive(p) ? .bust : .target
        }
        if engine.isLive(p),
           engine.players.indices.contains(where: { $0 != p && engine.assignedNumber(for: $0) == dart.value }) {
            return .checkout
        }
        return .normal
    }

    private func handleThrow(_ dart: Dart) {
        if engine.phase == .assignment {
            let playerName = engine.currentPlayer.name
            let assigned = engine.throwAssignmentDart(dart)
            if assigned {
                popup = PopupEvent(title: "\(dart.value)", subtitle: "\(playerName)'s number", icon: "scope", kind: .success, color: accent)
                HapticManager.shared.bigHit()
                SoundManager.shared.play(.doubleHit)
            } else {
                HapticManager.shared.dartThrown()
                SoundManager.shared.play(.dartHit)
            }
            return
        }

        let p = engine.currentPlayerIndex
        let playerName = engine.currentPlayer.name
        let cell = cellState(dart)
        let previousPlayerIndex = p

        let gameEnded = engine.throwDart(dart)

        if gameEnded {
            popup = .gameOver(winner: playerName)
            flashColor = Theme.scoreCheckout
            HapticManager.shared.checkout()
            SoundManager.shared.play(.checkout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGameOver = true
            }
            return
        }

        switch cell {
        case .target:
            popup = PopupEvent(title: "Going Live!", subtitle: "\(playerName) is live", icon: "flame.fill", kind: .success, color: accent)
            HapticManager.shared.bigHit()
            SoundManager.shared.play(.doubleHit)

        case .bust:
            popup = PopupEvent(title: "Self Hit!", subtitle: "Lost \(dart.multiplier.rawValue) life", icon: "heart.slash.fill", kind: .bust, color: Theme.bust)
            flashColor = Theme.bust
            HapticManager.shared.bust()
            SoundManager.shared.play(.bust)

        case .checkout:
            popup = PopupEvent(title: "Hit!", subtitle: "-\(dart.multiplier.rawValue) lives", icon: "burst.fill", kind: .danger, color: Theme.triple)
            HapticManager.shared.bigHit()
            SoundManager.shared.play(.tripleHit)

        default:
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

/// Per-player Killer card: claimed number, live/marks status, lives remaining.
struct KillerCard: View {
    var playerName: String
    var number: Int?
    var marks: Int
    var isLive: Bool
    var lives: Int
    var isActive: Bool
    var accent: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(isActive ? accent : Theme.textTertiary)
                    .frame(width: 8, height: 8)
                Text(playerName.uppercased())
                    .font(OcheFont.label(13))
                    .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: isLive ? "skull.fill" : "heart.fill")
                    .foregroundStyle(isLive ? Theme.bust : accent)
            }

            Text(number.map { "\($0)" } ?? "—")
                .font(OcheFont.scoreDisplay(isActive ? 44 : 32))
                .foregroundStyle(Theme.textPrimary)

            if !isLive {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i < marks ? accent : Theme.stroke)
                            .frame(width: 8, height: 8)
                    }
                }
            }

            HStack(spacing: 4) {
                ForEach(0..<max(lives, 0), id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.bust)
                }
                if lives == 0 {
                    Text("OUT")
                        .font(OcheFont.label(11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isActive ? accent.opacity(0.5) : Theme.stroke, lineWidth: isActive ? 2 : 1)
        )
    }
}
