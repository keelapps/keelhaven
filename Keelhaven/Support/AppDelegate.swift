import AppKit

/// A menu-bar-only app gives zero visible feedback when double-clicked while
/// already running — which reads as "the app won't open". Tell the user
/// where it lives instead.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Keelhaven is already running"
        alert.informativeText = "Look for its icon in the menu bar at the top right of your screen. Click it to manage your backups."
        alert.addButton(withTitle: "OK")
        alert.runModal()
        return false
    }
}
