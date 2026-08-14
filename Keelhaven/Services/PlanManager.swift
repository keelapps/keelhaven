import Foundation
import KeelhavenCore

/// Everything the wizard collects to create a plan.
struct PlanDraft {
    var name: String
    var sourcePaths: [String]
    var destination: Destination
    var schedule: Schedule
    var password: String
    var s3SecretKey: String?
}

/// Creates and deletes plans. Creation order matters for failure recovery:
/// secrets go into the Keychain first, then `restic init` proves the
/// destination works; on init failure the secrets are rolled back.
struct PlanManager {
    let keychain: KeychainStoring
    let resticBinaryURL: URL?

    func createPlan(_ draft: PlanDraft) async throws -> BackupPlan {
        guard let binaryURL = resticBinaryURL else {
            throw ResticError.binaryNotFound
        }

        let plan = BackupPlan(
            name: draft.name,
            sourcePaths: draft.sourcePaths,
            destination: draft.destination,
            schedule: draft.schedule
        )

        try keychain.setSecret(
            draft.password,
            account: KeychainAccount.repositoryPassword(planID: plan.id)
        )
        if let s3SecretKey = draft.s3SecretKey, !s3SecretKey.isEmpty {
            try keychain.setSecret(
                s3SecretKey,
                account: KeychainAccount.s3SecretKey(planID: plan.id)
            )
        }

        let credentials = RepoCredentials(
            repositoryPassword: draft.password,
            s3SecretAccessKey: draft.s3SecretKey
        )
        do {
            let runner = ResticRunner(binaryURL: binaryURL)
            _ = try await runner.run(
                .initRepository,
                destination: draft.destination,
                credentials: credentials,
                decoding: ResticInitResult.self
            )
        } catch {
            removeSecrets(planID: plan.id)
            throw error
        }

        return plan
    }

    func removeSecrets(planID: UUID) {
        try? keychain.deleteSecret(account: KeychainAccount.repositoryPassword(planID: planID))
        try? keychain.deleteSecret(account: KeychainAccount.s3SecretKey(planID: planID))
    }
}
