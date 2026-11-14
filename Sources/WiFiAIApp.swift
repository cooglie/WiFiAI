import SwiftUI

@main
struct WiFiAIApp: App {
    @StateObject private var store = ChatStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 700, minHeight: 500)
        }
    }
}
