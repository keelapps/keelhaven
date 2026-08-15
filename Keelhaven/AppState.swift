import AppKit
import Foundation
import Observation
import KeelhavenCore

enum PlanRunState: Equatable {
    case idle
    case running(progress: Double)
    case succeeded(Date)
    case failed(String)
}

/// Root observable state: owns the plan list, run states, and all services.
/// Backups are serialized — one at a time in v1.
@MainActor
@Observable
final class AppState {
    var plans: [BackupPlan] = []
    var runStates: [UUID: PlanRunState] = [:]
    var resticBinaryURL: URL?
    var startupError: String?
    /// True once bootstrap confirmed there are no plans — the trigger for the
    /// first-run welcome window.
    var shouldOfferWelcome = false

    @ObservationIgnored private let keychain: KeychainStoring = KeychainStore()
    @ObservationIgnored private let planStore = PlanStore()
    @ObservationIgnored private let historyStore = RunHistoryStore()
    @ObservationIgnored private let scheduler = SchedulerService()
    @ObservationIgnored private var wakeObserver: NSObjectProtocol?

    init() {
        resticBinaryURL = ResticLocator.locate()
        Task {
            await self.bootstrap()
        }
    }

    private func bootstrap() async {
        if let binaryURL = resticBinaryURL {
            let meetsMinimum = await ResticLocator.meetsMinimumVersion(at: binaryURL)
            if !meetsMinimum {
                startupError = String(localized: "Keelhaven needs restic \(ResticLocator.minimumVersionText) or newer. Update it with: brew upgrade restic")
            }
        }

        var plansLoadedCleanly = false
        do {
            plans = try await planStore.load()
            plansLoadedCleanly = true
        } catch {
            startupError = String(localized: "Could not load backup plans: \(error.localizedDescription)")
        }
        for plan in plans {
            runStates[plan.id] = .idle
        }
        // Offer the welcome window only when we know for sure there are no
        // plans — never on a load failure, where plans might exist on disk.
        if plansLoadedCleanly && plans.isEmpty {
            shouldOfferWelcome = true
        }

        await NotificationService.requestAuthorization()

        scheduler.start { [weak self] in
            Task { @MainActor in
                self?.runDuePlans()
            }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.runDuePlans()
            }
        }

        // Missed-run catch-up at launch.
        runDuePlans()
    }

    // MARK: - Menu bar

    /// What the menu bar shows. Idle is the Keelhaven mark (a template image in
    /// the asset catalog, so macOS tints it for light/dark and for the
    /// highlighted menu); the two transient states borrow SF Symbols, which
    /// already read as "working" and "something went wrong".
    enum MenuBarIcon: Equatable {
        case idle
        case symbol(String)
    }

    var menuBarIcon: MenuBarIcon {
        let states = runStates.values
        if states.contains(where: { if case .running = $0 { return true }; return false }) {
            return .symbol("arrow.triangle.2.circlepath")
        }
        if states.contains(where: { if case .failed = $0 { return true }; return false }) {
            return .symbol("exclamationmark.triangle")
        }
        return .idle
    }

    // MARK: - Plan lifecycle

    var planManager: PlanManager {
        PlanManager(keychain: keychain, resticBinaryURL: resticBinaryURL)
    }

    func createPlan(from draft: PlanDraft) async throws {
        let plan = try await planManager.createPlan(draft)
        plans.append(plan)
        runStates[plan.id] = .idle
        try await planStore.save(plans)
    }

    func renamePlan(_ plan: BackupPlan, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let index = plans.firstIndex(where: { $0.id == plan.id }) else { return }
        plans[index].name = trimmed
        Task {
            try? await planStore.save(plans)
        }
    }

    func deletePlan(_ plan: BackupPlan) {
        guard !isBackupRunning else { return }
        plans.removeAll { $0.id == plan.id }
        runStates.removeValue(forKey: plan.id)
        planManager.removeSecrets(planID: plan.id)
        Task {
            try? await planStore.save(plans)
            try? await historyStore.deleteHistory(for: plan.id)
        }
    }

    // MARK: - Running backups

    var isBackupRunning: Bool {
        runStates.values.contains { if case .running = $0 { return true }; return false }
    }

    private func runDuePlans() {
        guard !isBackupRunning else { return }
        let now = Date()
        if let due = plans.first(where: { SchedulePolicy.isDue($0, now: now) }) {
            runBackup(due)
        }
    }

    func runBackup(_ plan: BackupPlan) {
        guard !isBackupRunning else { return }
        guard let binaryURL = resticBinaryURL else {
            runStates[plan.id] = .failed(ResticError.binaryNotFound.localizedDescription)
            return
        }

        runStates[plan.id] = .running(progress: 0)
        Task {
            await self.performBackup(plan, binaryURL: binaryURL)
        }
    }

    private func performBackup(_ plan: BackupPlan, binaryURL: URL) async {
        let startedAt = Date()
        do {
            let credentials = try credentials(for: plan)
            let runner = ResticRunner(binaryURL: binaryURL)
            let stream = runner.backupStream(
                .backup(sources: plan.sourcePaths, excludes: plan.excludePatterns, tag: "keelhaven"),
                destination: plan.destination,
                credentials: credentials
            )

            var summary: BackupSummary?
            for try await event in stream {
                switch event {
                case .status(let status):
                    runStates[plan.id] = .running(progress: status.percentDone)
                case .summary(let value):
                    summary = value
                }
            }

            let record = BackupRunRecord(
                date: startedAt,
                success: true,
                snapshotID: summary?.snapshotID,
                filesNew: summary?.filesNew,
                filesChanged: summary?.filesChanged,
                dataAddedBytes: summary?.dataAdded,
                duration: summary?.totalDuration
            )
            await finishRun(plan, record: record)
            runStates[plan.id] = .succeeded(Date())
            await NotificationService.postBackupFinished(planName: plan.name, summary: summary)
        } catch {
            let message = (error as? ResticError)?.localizedDescription ?? error.localizedDescription
            let record = BackupRunRecord(date: startedAt, success: false, errorMessage: message)
            await finishRun(plan, record: record)
            runStates[plan.id] = .failed(message)
            await NotificationService.postBackupFailed(planName: plan.name, message: message)
        }
    }

    private func finishRun(_ plan: BackupPlan, record: BackupRunRecord) async {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index].lastRun = record
        }
        try? await planStore.save(plans)
        try? await historyStore.append(record, planID: plan.id)
    }

    /// For the Touch ID–gated "Copy Repository Password" action only.
    /// Callers must authenticate via BiometricAuthService first.
    func repositoryPassword(for plan: BackupPlan) -> String? {
        try? keychain.secret(account: KeychainAccount.repositoryPassword(planID: plan.id))
    }

    // MARK: - Restore

    /// The plan the restore window operates on, set before opening it.
    var restorePlanID: UUID?

    func restoreCredentials(for plan: BackupPlan) throws -> RepoCredentials {
        try credentials(for: plan)
    }

    private func credentials(for plan: BackupPlan) throws -> RepoCredentials {
        guard let password = try keychain.secret(
            account: KeychainAccount.repositoryPassword(planID: plan.id)
        ) else {
            throw ResticError.wrongPassword(message: "No password stored for this plan in the Keychain.")
        }
        var s3Secret: String?
        if case .s3 = plan.destination {
            s3Secret = try keychain.secret(account: KeychainAccount.s3SecretKey(planID: plan.id))
        }
        return RepoCredentials(repositoryPassword: password, s3SecretAccessKey: s3Secret)
    }
}
