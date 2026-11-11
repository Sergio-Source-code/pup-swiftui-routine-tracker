import SwiftUI

@main
struct MyApp: App {
    @State private var store = PupStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
