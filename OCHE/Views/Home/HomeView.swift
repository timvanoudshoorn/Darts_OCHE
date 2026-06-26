import SwiftUI

/// App entry screen — the real main menu: branding, then Play / Stats /
/// Settings as actual buttons (not a tab bar). "Play" drills into
/// `ModeSelectView` for the full game-mode list; Stats and Settings present
/// as sheets, same as before.
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

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    hero
                        .padding(.bottom, 36)

                    VStack(spacing: 12) {
                        NavigationLink(value: Route.modeSelect) {
                            MenuButton(title: "Play", icon: "target", style: .primary)
                        }
                        .buttonStyle(SquashButtonStyle())

                        Button { showStats = true } label: {
                            MenuButton(title: "Stats", icon: "chart.bar.xaxis", style: .secondary)
                        }
                        .buttonStyle(SquashButtonStyle())

                        Button { showSettings = true } label: {
                            MenuButton(title: "Settings", icon: "gearshape.fill", style: .secondary)
                        }
                        .buttonStyle(SquashButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.1), value: appeared)

                    Spacer(minLength: 0)

                    Text("DART MASTERS · \(versionString)")
                        .font(OcheFont.label(11))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .modeSelect:
                    ModeSelectView()
                case .setup(let mode):
                    SetupView(mode: mode)
                case .bullThrow(let mode, let config):
                    ThrowForBullView(mode: mode, config: config)
                case .play(let mode, let config):
                    GameRouterView(mode: mode, config: config)
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

    /// Hero header: wordmark + tagline above a slowly spinning dartboard.
    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.cyan.opacity(0.16))
                    .frame(width: 100, height: 100)
                    .blur(radius: 24)
                Dartboard()
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(boardRotation))
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
            }
            .onAppear {
                withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                    boardRotation = 360
                }
            }

            VStack(spacing: 4) {
                Text("DART MASTERS")
                    .font(OcheFont.scoreDisplay(34))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Pick a mode and start throwing.")
                    .font(OcheFont.body(14))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

/// A main-menu row: icon, title, chevron. `.primary` gets a solid brand-accent
/// fill (the one moment of color-as-action on this screen); `.secondary`
/// stays a flat surface tile, matching Direction F's "glow/fill is reserved
/// for the primary action" principle.
private struct MenuButton: View {
    enum Style { case primary, secondary }

    let title: String
    let icon: String
    let style: Style

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .frame(width: 22)
            Text(title.uppercased())
                .font(OcheFont.heading(17))
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .opacity(0.6)
        }
        .foregroundStyle(style == .primary ? Color.black : Theme.textPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(style == .primary ? Theme.cyan : Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style == .primary ? Color.clear : Theme.stroke, lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(SettingsStore())
}
