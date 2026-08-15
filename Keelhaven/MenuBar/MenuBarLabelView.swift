import SwiftUI

extension Notification.Name {
    /// Posted by AppDelegate when the user re-opens the already-running app
    /// (double-click in Finder / Dock). Handled here because AppDelegate has
    /// no access to AppState or the openWindow environment.
    static let keelhavenReopen = Notification.Name("KeelhavenReopen")
}

/// The MenuBarExtra label. It exists from launch for the app's whole
/// lifetime, which makes it the one reliable SwiftUI view for opening
/// windows on startup events in an LSUIElement app.
struct MenuBarLabelView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(systemName: appState.menuBarSymbolName)
            .accessibilityLabel("Keelhaven backup status")
            .onChange(of: appState.shouldOfferWelcome) { _, offer in
                // First launch with zero plans: open the welcome window,
                // unless the user has dismissed it before.
                guard offer,
                      !UserDefaults.standard.bool(forKey: WelcomeWindowView.dismissedDefaultsKey)
                else { return }
                openWelcome()
            }
            .onReceive(NotificationCenter.default.publisher(for: .keelhavenReopen)) { _ in
                // Explicit user intent: no plans → welcome (regardless of
                // earlier dismissal); plans exist → explain where the app lives.
                if appState.plans.isEmpty {
                    openWelcome()
                } else {
                    showAlreadyRunningAlert()
                }
            }
    }

    private func openWelcome() {
        openWindow(id: WindowID.welcome)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showAlreadyRunningAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = String(localized: "Keelhaven is already running")
        alert.informativeText = String(localized: "Look for its icon in the menu bar at the top right of your screen. Click it to manage your backups.\n\nDon't see the icon? Your menu bar is probably full — on Macs with a notch, macOS hides icons that don't fit. Quit another menu bar app or ⌘-drag an icon off the bar to make room, then relaunch Keelhaven.")
        alert.addButton(withTitle: String(localized: "OK"))
        alert.runModal()
    }
}
