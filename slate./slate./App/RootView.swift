import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .upcoming
    @State private var env = AppEnvironment.shared

    enum Tab: Hashable { case sports, upcoming, settings }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { SportsView() }
                .tabItem { Label("Sports", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.sports)

            NavigationStack { UpcomingView() }
                .tabItem { Label("Upcoming", systemImage: "calendar") }
                .tag(Tab.upcoming)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.Color.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .environment(env)
        .onChange(of: selection) { _, _ in Haptics.soft() }
    }
}

#Preview {
    RootView()
}
