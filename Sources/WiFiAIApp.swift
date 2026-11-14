import AppKit
import SwiftUI

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let store = ChatStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let root = ContentView().environmentObject(store)
        let hosting = NSHostingView(rootView: root)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WiFiAI"
        window.contentView = hosting
        window.center()
        window.minSize = NSSize(width: 700, height: 500)
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
