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
                            .spring(response: 0.5, dampingFraction: 0.85)
                                .delay(Double(idx) * 0.05),
                            value: appeared
                        )
                    }
                }
                .padding(20)
                .padding(.bottom, 32)
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
