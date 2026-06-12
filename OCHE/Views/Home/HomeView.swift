import SwiftUI

/// App entry screen: a fast, colorful list of game modes. Tapping one goes
/// straight to a quick setup screen, then into play — no accounts, no
/// interstitials.
struct HomeView: View {
    @StateObject private var router = AppRouter()
    @State private var showSettings = false
    @State private var showStats = false

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OCHE")
                                .font(OcheFont.scoreDisplay(56))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Pick a mode and start throwing.")
                                .font(OcheFont.body(15))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.top, 8)
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
