import SwiftUI
import KeelhavenCore

struct PlanStatusRow: View {
    @Environment(AppState.self) private var appState
    let plan: BackupPlan

    private var runState: PlanRunState {
        appState.runStates[plan.id] ?? .idle
    }

    /// Docker-style health dot: blue while running, green when the last
    /// backup succeeded, red when it failed, gray before the first run.
    private var statusColor: Color {
        switch runState {
        case .running:
            return .blue
        case .failed:
            return .red
        case .succeeded:
            return .green
        case .idle:
            guard let lastRun = plan.lastRun else { return .gray }
            return lastRun.success ? .green : .red
        }
    }

    private var statusAccessibilityLabel: String {
        switch runState {
        case .running: return "Backup running"
        case .failed: return "Last backup failed"
        case .succeeded: return "Backed up"
        case .idle:
            guard let lastRun = plan.lastRun else { return "Not backed up yet" }
            return lastRun.success ? "Backed up" : "Last backup failed"
        }
    }

    /// When the next scheduled run is due, shown as a tooltip on the status line.
    private var nextRunText: String {
        let next = SchedulePolicy.nextRun(
            for: plan.schedule,
            after: plan.lastRun?.date ?? Date(),
            calendar: .current
        )
        if next <= Date() {
            return "Next backup: as soon as possible"
        }
        return "Next backup: \(next.formatted(date: .abbreviated, time: .shortened))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 7, height: 7)
                            .accessibilityLabel(statusAccessibilityLabel)
                        Text(plan.name)
                            .fontWeight(.medium)
                    }
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
            Button {
                appState.runBackup(plan)
            } label: {
                Label("Back Up Now", systemImage: "arrow.triangle.2.circlepath")
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
            RelativeTimeText(prefix: "Backed up", date: date)
                .font(.caption)
                .foregroundStyle(.secondary)
                .help(nextRunText)
        case .idle:
            if let lastRun = plan.lastRun {
                if lastRun.success {
                    RelativeTimeText(prefix: "Last backup", date: lastRun.date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help(nextRunText)
                } else {
                    Text("Last backup failed")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .help(lastRun.errorMessage ?? "Last backup failed")
                }
            } else {
                Text("Not backed up yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help(nextRunText)
            }
        }
    }
}

/// "Backed up 5 seconds ago" that keeps counting up on its own (SwiftUI's
/// `.relative` text style live-updates), switching to an absolute date once
/// the moment is more than a day old — exactly the progression issue #19
/// asked for.
struct RelativeTimeText: View {
    let prefix: String
    let date: Date

    var body: some View {
        if Date().timeIntervalSince(date) < 24 * 60 * 60 {
            Text("\(prefix) ") + Text(date, style: .relative) + Text(" ago")
        } else {
            Text("\(prefix) on \(date.formatted(date: .abbreviated, time: .shortened))")
        }
    }
}
