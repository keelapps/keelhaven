import SwiftUI
import KeelhavenCore

enum WindowID {
    static let wizard = "wizard"
    static let about = "about"
    static let restore = "restore"
}

@main
struct KeelhavenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: appState.menuBarSymbolName)
                .accessibilityLabel("Keelhaven backup status")
        }
        .menuBarExtraStyle(.window)

        Window("New Backup Plan", id: WindowID.wizard) {
            WizardWindowView()
                .environment(appState)
        }
        .windowResizability(.contentSize)

        Window("Restore Backup", id: WindowID.restore) {
            RestoreWindowView()
                .environment(appState)
        }
        .windowResizability(.contentSize)

        Window("About Keelhaven", id: WindowID.about) {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
