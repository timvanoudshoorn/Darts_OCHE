import SwiftUI

/// Turn-by-turn breakdown of a completed match, built purely from the
/// persisted dart log. There's no "remaining score" column — `DartLogEntry`
/// has no stored remaining-score field for any mode, so showing one would
/// require a full per-mode engine replay, which is out of scope here.
struct MatchDetailView: View {
    let match: MatchRecord

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    ForEach(match.playerNames.indices, id: \.self) { i in
                        playerBreakdown(i)
                    }
                }
                .padding(Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationTitle(match.mode.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(match.playerNames.joined(separator: " vs "))
                .font(OcheFont.heading(20))
                .foregroundStyle(Theme.textPrimary)
            Text(match.date.formatted(date: .abbreviated, time: .shortened))
                .font(OcheFont.body(13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func playerBreakdown(_ i: Int) -> some View {
        let name = match.playerNames[i]
        let isWinner = i == match.winnerIndex
        let turns = match.dartLog.groupedByTurn(playerIndex: i)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name.uppercased())
                    .font(OcheFont.heading(16))
                    .foregroundStyle(isWinner ? match.mode.accentColor : Theme.textPrimary)
                if isWinner {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Theme.scoreCheckout)
                }
                Spacer()
            }

            if turns.isEmpty {
                Text("No darts recorded for this match.")
                    .font(OcheFont.body(13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(turns, id: \.turnIndex) { turn in
                        turnRow(turn.turnIndex, turn.darts)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle(cornerRadius: Corner.xl)
    }

    private func turnRow(_ turnIndex: Int, _ darts: [DartLogEntry]) -> some View {
        let bust = darts.contains { $0.isBust }
        let checkout = darts.contains { $0.isCheckoutHit }
        let points = bust ? 0 : darts.reduce(0) { $0 + $1.dart.points }

        return HStack {
            Text("R\(turnIndex + 1)")
                .font(OcheFont.label(11))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 28, alignment: .leading)

            Text(darts.map { $0.dart.label }.joined(separator: "  "))
                .font(OcheFont.body(13))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if bust {
                Text("BUST")
                    .font(OcheFont.label(11))
                    .foregroundStyle(Theme.bust)
            } else if checkout {
                Text("\(points) · OUT")
                    .font(OcheFont.bodyBold(13))
                    .foregroundStyle(Theme.scoreCheckout)
            } else {
                Text("\(points)")
                    .font(OcheFont.bodyBold(13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}
