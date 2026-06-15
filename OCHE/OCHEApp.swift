import SwiftUI
import SwiftData

@main
struct OCHEApp: App {
    @StateObject private var settings: SettingsStore

    init() {
        FontLoader.registerBundledFonts()
        _settings = StateObject(wrappedValue: SettingsStore())
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(settings)
        }
        .modelContainer(for: [PlayerProfile.self, MatchRecord.self])
    }
}
