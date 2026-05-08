import SwiftUI

@main
struct spotrackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 800, height: 500)
        }
        .windowResizability(.contentSize)
    }
}
