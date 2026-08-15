import SwiftUI
import KeelhavenCore

struct PlanStatusRow: View {
    @Environment(AppState.self) private var appState
    let plan: BackupPlan

    private var runState: PlanRunState {
        appState.runStates[plan.id] ?? .idle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(plan.name)
                        .fontWeight(.medium)
                    Text(plan.destination.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                trailingControl
                planActionsMenu
            }
            statusLine
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .contextMenu {
            planActions
        }
    }

    /// Visible entry point for per-plan actions — the context menu alone was
    /// too hidden to discover (issue #11).
    private var planActionsMenu: some View {
        Menu {
            planActions
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Actions for \(plan.name)")
    }

    @ViewBuilder
    private var planActions: some View {
        Button("Rename…") {
            promptRename()
        }
        Button("Copy Repository Password") {
            copyPassword()
        }
        Divider()
        Button("Delete Backup Plan…", role: .destructive) {
            confirmAndDelete()
        }
        .disabled(appState.isBackupRunning)
    }

    /// Confirmation dialogs use app-modal NSAlert, not SwiftUI `.alert`:
    /// inside a MenuBarExtra window, clicking an alert button tears down the
    /// panel and the follow-up work silently dies with it (issue #11).
    /// `NSApp.activate` first — an LSUIElement app that just lost its panel
    /// isn't active, and the modal/Touch ID dialogs need key status to show.

    private func promptRename() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Rename “\(plan.name)”"
        let field = NSTextField(string: plan.name)
        field.frame = NSRect(x: 0, y: 0, width: 220, height: 24)
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        appState.renamePlan(plan, to: field.stringValue)
    }

    private func confirmAndDelete() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Delete “\(plan.name)”?"
        alert.informativeText = "Removes the plan and its saved password from this Mac. Already backed-up data at the destination is not deleted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete").hasDestructiveAction = true
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        deletePlan()
    }

    /// Both actions below are gated behind Touch ID (login password fallback
    /// on Macs without it).

    private func copyPassword() {
        NSApp.activate(ignoringOtherApps: true)
        Task {
            guard await BiometricAuthService.authenticate(
                reason: "copy the backup password for “\(plan.name)”"
            ) else { return }
            guard let password = appState.repositoryPassword(for: plan) else { return }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(password, forType: .string)
        }
    }

    private func deletePlan() {
        NSApp.activate(ignoringOtherApps: true)
        Task {
            guard await BiometricAuthService.authenticate(
                reason: "delete the backup plan “\(plan.name)”"
            ) else { return }
            appState.deletePlan(plan)
        }
    }

    @ViewBuilder
    private var trailingControl: some View {
        switch runState {
        case .running:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Backup in progress")
        default:
            Button("Back Up Now") {
                appState.runBackup(plan)
            }
            .controlSize(.small)
            .disabled(appState.isBackupRunning || appState.resticBinaryURL == nil)
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch runState {
        case .running(let progress):
            ProgressView(value: progress)
                .controlSize(.small)
                .accessibilityLabel("Backup \(Int(progress * 100)) percent done")
        case .failed(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(3)
                .help(message)
        case .succeeded(let date):
            Text("Backed up \(date.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .idle:
            if let lastRun = plan.lastRun {
                if lastRun.success {
                    Text("Last backup \(lastRun.date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Last backup failed")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } else {
                Text("Not backed up yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
