import SwiftUI
import KeelhavenCore

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var startAtLogin = LoginItemService.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Keelhaven")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(id: WindowID.about)
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("About Keelhaven")
                .accessibilityLabel("About Keelhaven")
            }

            if let startupError = appState.startupError {
                Label(startupError, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            if appState.resticBinaryURL == nil {
                Label(
                    "restic was not found. Install it with: brew install restic",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.callout)
                .foregroundStyle(.orange)
            }

            Divider()

            if appState.plans.isEmpty {
                Text("No backup plans yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appState.plans) { plan in
                    PlanStatusRow(plan: plan)
                }
            }

            Divider()

            Button {
                openWizard()
            } label: {
                Label("Add Backup Plan…", systemImage: "plus")
            }
            .disabled(appState.resticBinaryURL == nil)

            Toggle("Start at Login", isOn: $startAtLogin)
                .onChange(of: startAtLogin) { _, newValue in
                    do {
                        try LoginItemService.setEnabled(newValue)
                    } catch {
                        startAtLogin = LoginItemService.isEnabled
                    }
                }

            Divider()

            Button("Quit Keelhaven") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 340)
    }

    private func openWizard() {
        openWindow(id: WindowID.wizard)
        // LSUIElement apps don't come forward on their own.
        NSApp.activate(ignoringOtherApps: true)
    }
}
