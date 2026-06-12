import SwiftUI
import SwiftData
import Charts

/// Stats & history screen: lifetime aggregates per player plus a chart of
/// 3-dart averages over recent matches.
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PlayerProfile.totalMatchesPlayed, order: .reverse)
    private var profiles: [PlayerProfile]

    @Query(sort: \MatchRecord.date, order: .reverse)
    private var matches: [MatchRecord]

    @State private var selectedPlayer: String? = nil

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("STATS")
                            .font(OcheFont.heading(32))
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(.top, 8)

                    if profiles.isEmpty {
                        emptyState
                    } else {
                        playerPicker

                        if let name = selectedPlayer, let profile = profiles.first(where: { $0.name == name }) {
                            lifetimeCard(profile)
                            averageChart(for: name)
                        }

                        recentMatchesSection
                    }
                }
                .padding(20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            if selectedPlayer == nil {
                selectedPlayer = profiles.first?.name
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(Theme.textTertiary)
            Text("No matches yet")
                .font(OcheFont.heading(20))
            Text("Play a match to start building your stats.")
                .font(OcheFont.body(14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: Player picker

    private var playerPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(profiles, id: \.id) { profile in
                    let isSelected = profile.name == selectedPlayer
                    Button {
                        selectedPlayer = profile.name
                    } label: {
                        Text(profile.name.uppercased())
                            .font(OcheFont.bodyBold(14))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? Theme.glowTeal.opacity(0.22) : Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(isSelected ? Theme.glowTeal : Theme.stroke, lineWidth: isSelected ? 2 : 1)
                            )
                            .foregroundStyle(isSelected ? Theme.glowTeal : Theme.textSecondary)
                    }
                    .buttonStyle(SquashButtonStyle())
                }
            }
        }
    }

    // MARK: Lifetime card

    private func lifetimeCard(_ profile: PlayerProfile) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                statBlock("MATCHES", "\(profile.totalMatchesPlayed)")
                statBlock("WINS", "\(profile.totalMatchesWon)")
                statBlock("WIN %", profile.totalMatchesPlayed > 0
                          ? String(format: "%.0f%%", Double(profile.totalMatchesWon) / Double(profile.totalMatchesPlayed) * 100)
                          : "—")
            }
            HStack(spacing: 0) {
                statBlock("3-DART AVG", String(format: "%.1f", profile.lifetimeThreeDartAverage))
                statBlock("BEST AVG", String(format: "%.1f", profile.bestThreeDartAverage))
                statBlock("BEST CHECKOUT", profile.bestCheckoutPoints > 0 ? "\(profile.bestCheckoutPoints)" : "—")
            }
            HStack(spacing: 16) {
                Label("\(profile.total100Plus) × 100+", systemImage: "100.circle")
                Label("\(profile.total140Plus) × 140+", systemImage: "flame")
                Label("\(profile.total180s) × 180", systemImage: "star.fill")
            }
            .font(OcheFont.body(12))
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.stroke, lineWidth: 1))
    }

    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(OcheFont.heading(22))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(OcheFont.label(10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Average chart

    private struct AveragePoint: Identifiable {
        let id: UUID
        let date: Date
        let average: Double
    }

    private func averagePoints(for playerName: String) -> [AveragePoint] {
        matches
            .sorted { $0.date < $1.date }
            .compactMap { match -> AveragePoint? in
                guard let idx = match.playerNames.firstIndex(of: playerName) else { return nil }
                let stats = match.stats
                guard idx < stats.count, stats[idx].dartsThrown > 0 else { return nil }
                return AveragePoint(id: match.id, date: match.date, average: stats[idx].threeDartAverage)
            }
            .suffix(20)
            .map { $0 }
    }

    private func averageChart(for playerName: String) -> some View {
        let points = averagePoints(for: playerName)

        return VStack(alignment: .leading, spacing: 12) {
            Text("3-DART AVERAGE")
                .font(OcheFont.label(13))
                .foregroundStyle(Theme.textTertiary)

            if points.isEmpty {
                Text("No standard-darts matches yet.")
                    .font(OcheFont.body(13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Match", point.date),
                        y: .value("Average", point.average)
                    )
                    .foregroundStyle(Theme.glowTeal)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Match", point.date),
                        y: .value("Average", point.average)
                    )
                    .foregroundStyle(Theme.glowTeal)
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.stroke, lineWidth: 1))
    }

    // MARK: Recent matches

    private var recentMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT MATCHES")
                .font(OcheFont.label(13))
                .foregroundStyle(Theme.textTertiary)

            ForEach(matches.prefix(15), id: \.id) { match in
                matchRow(match)
            }
        }
    }

    private func matchRow(_ match: MatchRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(match.mode.title)
                    .font(OcheFont.bodyBold(15))
                    .foregroundStyle(Theme.textPrimary)
                Text(match.playerNames.joined(separator: " vs "))
                    .font(OcheFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let winnerIndex = match.winnerIndex, winnerIndex < match.playerNames.count {
                    Text(match.playerNames[winnerIndex])
                        .font(OcheFont.bodyBold(13))
                        .foregroundStyle(match.mode.accentColor)
                }
                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                    .font(OcheFont.body(11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}
