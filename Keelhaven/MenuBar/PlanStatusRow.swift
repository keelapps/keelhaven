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
            }
            statusLine
        }
        .padding(.vertical, 2)
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
