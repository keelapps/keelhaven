import SwiftUI
import KeelhavenCore

enum WindowID {
    static let wizard = "wizard"
    static let about = "about"
    static let restore = "restore"
    static let welcome = "welcome"
    static let editPlan = "editPlan"
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
            MenuBarLabelView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Window("Welcome to Keelhaven", id: WindowID.welcome) {
            WelcomeWindowView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

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

        Window("Edit Backup Plan", id: WindowID.editPlan) {
            EditPlanWindowView()
                .environment(appState)
        }
        .windowResizability(.contentSize)

        Window("About Keelhaven", id: WindowID.about) {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
