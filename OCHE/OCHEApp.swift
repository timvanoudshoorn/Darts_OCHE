import SwiftUI
import SwiftData

@main
struct OCHEApp: App {
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(settings)
        }
        .modelContainer(for: [PlayerProfile.self, MatchRecord.self])
    }
}
