import SwiftUI

/// First-run welcome: explains the app in plain language and hands the user
/// straight to the wizard with one big button. Auto-opened at launch when no
/// plans exist (see MenuBarLabelView); reachable again by double-clicking the
/// app while it runs.
struct WelcomeWindowView: View {
    static let dismissedDefaultsKey = "welcomeDismissed"

    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            Text("Welcome to Keelhaven")
                .font(.largeTitle.bold())

            Text("Keelhaven automatically copies your important folders to a backup drive, so nothing is lost if your Mac ever breaks or goes missing.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 24) {
                stepColumn(number: 1, symbol: "folder", text: String(localized: "Pick your folders"))
                stepArrow
                stepColumn(number: 2, symbol: "externaldrive", text: String(localized: "Pick a backup drive"))
                stepArrow
                stepColumn(number: 3, symbol: "calendar.badge.clock", text: String(localized: "It runs by itself every day"))
            }
            .padding(.vertical, 8)

            Button {
                markDismissed()
                dismiss()
                openWindow(id: WindowID.wizard)
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Text("Set Up Your First Backup")
                    .font(.title3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Button("Later") {
                markDismissed()
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 540)
        .onChange(of: appState.plans.count) { _, count in
            // A plan got created (via the wizard) — the welcome has done its job.
            if count > 0 {
                dismiss()
            }
        }
    }

    private var stepArrow: some View {
        Image(systemName: "arrow.right")
            .font(.title3)
            .foregroundStyle(.tertiary)
            .padding(.top, 22)
            .accessibilityHidden(true)
    }

    private func stepColumn(number: Int, symbol: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 34))
                .foregroundStyle(Color.accentColor)
                .frame(height: 44)
                .accessibilityHidden(true)
            Text("\(number). \(text)")
                .font(.callout)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 120)
    }

    private func markDismissed() {
        UserDefaults.standard.set(true, forKey: Self.dismissedDefaultsKey)
    }
}
