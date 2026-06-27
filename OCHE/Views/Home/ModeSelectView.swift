import SwiftUI

/// The full game-mode list — reached from the Main Menu's "Play" button,
/// not the app's landing screen (see `HomeView`).
struct ModeSelectView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(GameMode.allCases.enumerated()), id: \.element) { idx, mode in
                        NavigationLink(value: Route.setup(mode)) {
                            ModeCard(mode: mode)
                        }
                        .buttonStyle(SquashButtonStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            Motion.reveal.delay(Double(idx) * 0.05),
                            value: appeared
                        )
                    }
                }
                .padding(Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationTitle("All Modes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(Theme.textPrimary)
        .onAppear { appeared = true }
    }
}

#Preview {
    NavigationStack {
        ModeSelectView()
    }
}
