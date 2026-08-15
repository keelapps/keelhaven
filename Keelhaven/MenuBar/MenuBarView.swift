import SwiftUI
import KeelhavenCore

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var startAtLogin = LoginItemService.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Keelhaven")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button {
                    openWindow(id: WindowID.about)
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nothing is backed up yet.")
                        .foregroundStyle(.secondary)
                    Button {
                        openWizard()
                    } label: {
                        Label("Set Up a Backup", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.resticBinaryURL == nil)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(appState.plans) { plan in
                        PlanStatusRow(plan: plan)
                    }
                }
            }

            Divider()

            Button {
                openWizard()
            } label: {
                Label("Add Backup Plan…", systemImage: "plus")
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(appState.resticBinaryURL == nil)

            Divider()

            // App-level controls share the last section, like a system menu:
            // the toggle and Quit belong together, actions live above.
            HStack {
                Text("Start at Login")
                Spacer()
                Toggle("Start at Login", isOn: $startAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(.green)
                    .onChange(of: startAtLogin) { _, newValue in
                        do {
                            try LoginItemService.setEnabled(newValue)
                        } catch {
                            startAtLogin = LoginItemService.isEnabled
                        }
                    }
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Text("Quit Keelhaven")
                    Spacer()
                    Text("⌘Q")
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(16)
        .frame(width: 340)
    }

    private func openWizard() {
        openWindow(id: WindowID.wizard)
        // LSUIElement apps don't come forward on their own.
        NSApp.activate(ignoringOtherApps: true)
    }
}
