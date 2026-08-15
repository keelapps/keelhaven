import AppKit

/// A menu-bar-only app gives zero visible feedback when double-clicked while
/// already running. The delegate can't see AppState or open SwiftUI windows,
/// so it forwards the event; MenuBarLabelView decides what to show.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        NotificationCenter.default.post(name: .keelhavenReopen, object: nil)
        return false
    }
}
