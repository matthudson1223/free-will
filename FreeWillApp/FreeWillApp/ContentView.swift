import SwiftUI

struct ContentView: View {
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"

    var preferredScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some View {
        TabView {
            ChatView()
                .tabItem { Label("Chat", systemImage: "message") }
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.pages") }
            HabitsView()
                .tabItem { Label("Habits", systemImage: "checkmark.circle") }
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(preferredScheme)
    }
}
