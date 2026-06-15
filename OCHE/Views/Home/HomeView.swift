import SwiftUI

/// App entry screen: a fast, colorful list of game modes. Tapping one goes
/// straight to a quick setup screen, then into play — no accounts, no
/// interstitials.
struct HomeView: View {
    @StateObject private var router = AppRouter()
    @State private var showSettings = false
    @State private var showStats = false
    @State private var boardRotation: Double = 0
    @State private var appeared = false

    /// Surfaced on the home footer so a freshly sideloaded build is provably
    /// the new one (reads CFBundleShortVersionString / CFBundleVersion).
    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) · build \(b)"
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        hero

                        Rectangle()
                            .fill(Theme.accentGradient)
                            .frame(height: 2)
                            .opacity(0.35)
                            .clipShape(Capsule())
                            .padding(.bottom, 2)

                        ForEach(Array(GameMode.allCases.enumerated()), id: \.element) { idx, mode in
                            NavigationLink(value: Route.setup(mode)) {
                                ModeCard(mode: mode)
                            }
                            .buttonStyle(SquashButtonStyle())
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 28)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.82)
                                    .delay(0.05 + Double(idx) * 0.06),
                                value: appeared
                            )
                        }

                        Text("OCHE · \(versionString)")
                            .font(OcheFont.label(11))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 14)
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
        .onAppear { appeared = true }
    }

    /// Hero header: the gradient wordmark + tagline alongside a slowly spinning
    /// dartboard sitting on a soft accent glow.
    private var hero: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("OCHE")
                    .font(OcheFont.scoreDisplay(64))
                    .foregroundStyle(Theme.accentGradient)
                    .shadow(color: Theme.cyan.opacity(0.35), radius: 18)
                Text("Pick a mode and start throwing.")
                    .font(OcheFont.body(15))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 108, height: 108)
                    .blur(radius: 28)
                    .opacity(0.4)
                Dartboard()
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(boardRotation))
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
            }
            .onAppear {
                withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                    boardRotation = 360
                }
            }
        }
        .padding(.top, 6)
    }
}

#Preview {
    HomeView()
        .environmentObject(SettingsStore())
}
