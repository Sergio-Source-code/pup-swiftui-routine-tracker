import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            HistoryView()
                .tabItem { Label("Activity", systemImage: "clock.fill") }
            PupsView()
                .tabItem { Label("Pups", systemImage: "pawprint.fill") }
        }
    }
}
