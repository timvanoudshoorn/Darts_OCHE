import SwiftUI

/// App entry screen: a fast, colorful list of game modes. Tapping one goes
/// straight to a quick setup screen, then into play — no accounts, no
/// interstitials.
struct HomeView: View {
    @StateObject private var router = AppRouter()
    @State private var showSettings = false
    @State private var showStats = false
    @State private var boardRotation: Double = 0

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("OCHE")
                                    .font(OcheFont.scoreDisplay(56))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Pick a mode and start throwing.")
                                    .font(OcheFont.body(15))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer(minLength: 0)

                            Dartboard()
                                .frame(width: 92, height: 92)
                                .rotationEffect(.degrees(boardRotation))
                                .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
                                .onAppear {
                                    withAnimation(.linear(duration: 140).repeatForever(autoreverses: false)) {
                                        boardRotation = 360
                                    }
                                }
                        }
                        .padding(.top, 8)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.woodLight, Theme.wood, Theme.woodDark],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .padding(.bottom, 8)

                        ForEach(GameMode.allCases) { mode in
                            NavigationLink(value: Route.setup(mode)) {
                                ModeCard(mode: mode)
                            }
                            .buttonStyle(SquashButtonStyle())
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .setup(let mode):
                    SetupView(mode: mode)
                case .bullThrow(let mode, let config):
                    ThrowForBullView(mode: mode, config: config)
                case .play(let mode, let config):
                    GameRouterView(mode: mode, config: config)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                    .accessibilityLabel("Stats")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(Theme.textPrimary)
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
        }
        .environmentObject(router)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    HomeView()
        .environmentObject(SettingsStore())
}
