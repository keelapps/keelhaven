import SwiftUI
import KeelhavenCore

enum WindowID {
    static let wizard = "wizard"
}

@main
struct KeelhavenApp: App {
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
    }
}
