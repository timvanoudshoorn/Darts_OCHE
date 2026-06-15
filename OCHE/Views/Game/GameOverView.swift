import SwiftUI
import SwiftData

/// Shared end-of-match summary: winner, per-player stats (computed fresh from
/// the dart log so Undo/edits are always reflected accurately), and actions
/// to play again or return home. Persists a `MatchRecord` and folds the
/// result into each player's `PlayerProfile` on appear.
struct GameOverView: View {
    let mode: GameMode
    let players: [GamePlayer]
    let winnerIndex: Int?
    let dartLog: [DartLogEntry]
    /// Optional extra line per player (e.g. "0 remaining", "Lives: 3").
    var extraInfo: (Int) -> String? = { _ in nil }
    var winnerNote: String? = nil

    /// If `nil`, the default behavior (via `AppRouter`) is used: "Play Again"
    /// pushes a fresh match with `config`, "Home" pops to root.
    var onPlayAgain: (() -> Void)? = nil
    var onHome: (() -> Void)? = nil
    var config: GameLaunchConfig

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: AppRouter
    @State private var saved = false
    @State private var revealed = false

    private var stats: [MatchStatistics] {
        players.indices.map { MatchStatistics.compute(from: dartLog, playerIndex: $0) }
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Theme.accentGradient)
                            .shadow(color: Theme.cyan.opacity(0.4), radius: 16)
                            .scaleEffect(revealed ? 1 : 0.4)
                            .rotationEffect(.degrees(revealed ? 0 : -18))
                        Text(winnerIndex == nil ? "Session Complete" : "Winner")
                            .font(OcheFont.label(14))
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(2)
                        if let winnerIndex {
                            Text(players[winnerIndex].name.uppercased())
                                .font(OcheFont.scoreDisplay(52))
                                .foregroundStyle(Theme.accentGradient)
                                .scaleEffect(revealed ? 1 : 0.7)
                                .opacity(revealed ? 1 : 0)
                            if let winnerNote {
                                Text(winnerNote)
                                    .font(OcheFont.body(14))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        } else {
                            Text("No Result")
                                .font(OcheFont.scoreDisplay(40))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        ForEach(players.indices, id: \.self) { i in
                            playerStatsCard(i)
                        }
                    }

                    VStack(spacing: 12) {
                        Button(action: { (onPlayAgain ?? defaultPlayAgain)() }) {
                            Text("PLAY AGAIN")
                                .font(OcheFont.heading(20))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 18).fill(mode.accentColor))
                                .foregroundStyle(Color.black)
                        }
                        Button(action: { (onHome ?? defaultHome)() }) {
                            Text("HOME")
                                .font(OcheFont.heading(18))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
                                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.stroke, lineWidth: 1))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .buttonStyle(SquashButtonStyle())
                    .padding(.bottom, 32)
                }
                .padding(20)
            }

            if winnerIndex != nil {
                ConfettiBurst()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            saveResult()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                revealed = true
            }
        }
    }

    private func defaultPlayAgain() {
        router.restart(mode: mode, config: config)
    }

    private func defaultHome() {
        router.popToRoot()
    }

    private func playerStatsCard(_ i: Int) -> some View {
        let s = stats[i]
        let isWinner = i == winnerIndex

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(players[i].name.uppercased())
                    .font(OcheFont.heading(18))
                    .foregroundStyle(isWinner ? mode.accentColor : Theme.textPrimary)
                if isWinner {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Theme.scoreCheckout)
                }
                Spacer()
                if let extra = extraInfo(i) {
                    Text(extra)
                        .font(OcheFont.body(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 0) {
                statBlock("3-DART AVG", String(format: "%.1f", s.threeDartAverage))
                statBlock("FIRST 9 AVG", String(format: "%.1f", s.firstNineAverage))
                statBlock("HIGHEST", "\(s.highestTurn)")
                statBlock("CHECKOUT %", s.checkoutAttempts > 0 ? String(format: "%.0f%%", s.checkoutPercentage) : "—")
            }

            HStack(spacing: 16) {
                Label("\(s.oneHundredPlus) × 100+", systemImage: "100.circle")
                Label("\(s.oneFortyPlus) × 140+", systemImage: "flame")
                Label("\(s.oneEightys) × 180", systemImage: "star.fill")
            }
            .font(OcheFont.body(12))
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isWinner ? mode.accentColor.opacity(0.5) : Theme.stroke, lineWidth: isWinner ? 2 : 1)
        )
    }

    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(OcheFont.heading(20))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(OcheFont.label(10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func saveResult() {
        guard !saved else { return }
        saved = true

        let record = MatchRecord(mode: mode, playerNames: players.map(\.name), winnerIndex: winnerIndex, stats: stats)
        modelContext.insert(record)

        for (i, player) in players.enumerated() {
            let name = player.name
            let descriptor = FetchDescriptor<PlayerProfile>(predicate: #Predicate { $0.name == name })
            let profile = (try? modelContext.fetch(descriptor))?.first ?? {
                let new = PlayerProfile(name: name)
                modelContext.insert(new)
                return new
            }()

            var finishedPoints: Int? = nil
            if i == winnerIndex, mode == .standard {
                finishedPoints = stats[i].dartsThrown > 0 ? lastTurnPoints(for: i) : nil
            }

            profile.record(stats: stats[i], won: i == winnerIndex, finishedPoints: finishedPoints)
        }

        try? modelContext.save()
    }

    /// The total points of the player's final (checkout) turn — used to track
    /// "best checkout" on their profile.
    private func lastTurnPoints(for playerIndex: Int) -> Int? {
        let entries = dartLog.filter { $0.playerIndex == playerIndex }
        guard let lastTurn = entries.last?.turnIndex else { return nil }
        return entries.filter { $0.turnIndex == lastTurn }.reduce(0) { $0 + $1.dart.points }
    }
}
