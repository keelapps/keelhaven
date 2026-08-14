import SwiftUI
import KeelhavenCore

struct PlanStatusRow: View {
    @Environment(AppState.self) private var appState
    let plan: BackupPlan
    @State private var confirmingDelete = false

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
            }
            statusLine
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Copy Repository Password") {
                copyPassword()
            }
            Divider()
            Button("Delete Backup Plan…", role: .destructive) {
                confirmingDelete = true
            }
            .disabled(appState.isBackupRunning)
        }
        .alert("Delete “\(plan.name)”?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                deletePlan()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes the plan and its saved password from this Mac. Already backed-up data at the destination is not deleted.")
        }
    }

    /// Both actions below are gated behind Touch ID (login password fallback
    /// on Macs without it).

    private func copyPassword() {
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
                .lineLimit(2)
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
