import SwiftUI

/// Quick setup: player names + mode-specific options, then straight into play.
struct SetupView: View {
    let mode: GameMode

    @EnvironmentObject private var router: AppRouter
    @State private var playerNames: [String]
    @State private var config = GameLaunchConfig()
    @State private var throwForBull = true

    init(mode: GameMode) {
        self.mode = mode
        let defaultCount = mode == .killer ? 2 : 2
        _playerNames = State(initialValue: (1...defaultCount).map { "Player \($0)" })
    }

    private var canAddPlayer: Bool { playerNames.count < mode.playerRange.upperBound }
    private var canRemovePlayer: Bool { playerNames.count > mode.playerRange.lowerBound }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.title.uppercased())
                            .font(OcheFont.heading(32))
                            .foregroundStyle(mode.accentColor)
                        Text(mode.subtitle)
                            .font(OcheFont.body(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    playersSection
                    optionsSection

                    if playerNames.count > 1 {
                        bullThrowSection
                    }

                    Button {
                        config.players = playerNames.map { GamePlayer(name: $0.isEmpty ? "Player" : $0) }
                        if throwForBull {
                            router.path.append(Route.bullThrow(mode, config))
                        } else {
                            router.path.append(Route.play(mode, config))
                        }
                    } label: {
                        Text("START")
                            .font(OcheFont.heading(22))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(mode.accentColor)
                            )
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(SquashButtonStyle())
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(20)
            }
        }
        .navigationTitle("Setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: Players

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Players")

            ForEach(playerNames.indices, id: \.self) { i in
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(mode.accentColor)
                        .frame(width: 24)
                    TextField("Player \(i + 1)", text: $playerNames[i])
                        .font(OcheFont.body(17))
                        .textFieldStyle(.plain)
                        .foregroundStyle(Theme.textPrimary)

                    if canRemovePlayer {
                        Button {
                            playerNames.remove(at: i)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Theme.bust)
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.stroke, lineWidth: 1))
            }

            if canAddPlayer {
                Button {
                    playerNames.append("Player \(playerNames.count + 1)")
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Player")
                            .font(OcheFont.bodyBold(15))
                    }
                    .foregroundStyle(mode.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).strokeBorder(mode.accentColor.opacity(0.4), lineWidth: 1.5, antialiased: true))
                }
                .buttonStyle(SquashButtonStyle())
            }
        }
    }

    // MARK: Throw for the bull

    private var bullThrowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Throw Order")
            toggleRow(
                "Throw for the Bull",
                isOn: $throwForBull,
                subtitle: "Each player throws one dart at the bull — closest goes first"
            )
        }
    }

    // MARK: Mode-specific options

    @ViewBuilder
    private var optionsSection: some View {
        switch mode {
        case .standard:
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Starting Score")
                HStack(spacing: 12) {
                    scoreChoice(301)
                    scoreChoice(501)
                }
            }

        case .aroundTheClock:
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Options")
                toggleRow("Finish on Bull", isOn: $config.finishOnBull)
                toggleRow("Multipliers Count", isOn: $config.multipliersCount, subtitle: "Doubles/triples skip ahead in the sequence")
                toggleRow("Reverse", isOn: $config.reverse, subtitle: "Run the sequence backwards")
            }

        case .countUp:
            stepperRow("Rounds", value: $config.totalRounds, range: 1...20)

        case .killer:
            stepperRow("Lives", value: $config.startingLives, range: 1...10)

        case .cricket, .halveIt, .practice170:
            EmptyView()
        }
    }

    private func scoreChoice(_ score: Int) -> some View {
        let isSelected = config.startingScore == score
        return Button {
            config.startingScore = score
        } label: {
            Text("\(score)")
                .font(OcheFont.heading(28))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? mode.accentColor.opacity(0.22) : Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isSelected ? mode.accentColor : Theme.stroke, lineWidth: isSelected ? 2 : 1)
                )
                .foregroundStyle(isSelected ? mode.accentColor : Theme.textSecondary)
        }
        .buttonStyle(SquashButtonStyle())
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(OcheFont.label(13))
            .foregroundStyle(Theme.textTertiary)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(isOn: isOn) {
                Text(title)
                    .font(OcheFont.bodyBold(15))
                    .foregroundStyle(Theme.textPrimary)
            }
            .tint(mode.accentColor)

            if let subtitle {
                Text(subtitle)
                    .font(OcheFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.stroke, lineWidth: 1))
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title)
            HStack {
                Text("\(value.wrappedValue)")
                    .font(OcheFont.heading(28))
                    .foregroundStyle(mode.accentColor)
                Spacer()
                Stepper("", value: value, in: range)
                    .labelsHidden()
                    .tint(mode.accentColor)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.stroke, lineWidth: 1))
        }
    }
}
