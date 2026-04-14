import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = "today"

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag("today")

            ScheduleViewV2()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag("schedule")

            FlyView()
                .tabItem {
                    Label("Fly", systemImage: "airplane.departure")
                }
                .tag("fly")

            FleetListView()
                .tabItem {
                    Label("Fleet", systemImage: "airplane")
                }
                .tag("fleet")

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag("more")
        }
        .tint(.brandBlue)
    }
}
