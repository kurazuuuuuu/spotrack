import SwiftUI

@main
struct spotrackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 1200, height: 750)
        }
        .windowResizability(.contentSize)
    }
}
