import Foundation

/// Abstracts Keychain access so the engine and tests never touch Security
/// framework state directly.
public protocol KeychainStoring: Sendable {
    func setSecret(_ secret: String, account: String) throws
    func secret(account: String) throws -> String?
    func deleteSecret(account: String) throws
}

/// Well-known account names, one secret per plan.
public enum KeychainAccount {
    public static func repositoryPassword(planID: UUID) -> String {
        "repo-password.\(planID.uuidString)"
    }

    public static func s3SecretKey(planID: UUID) -> String {
        "s3-secret.\(planID.uuidString)"
    }
}

public enum KeychainError: Error, Equatable, Sendable {
    case unexpectedStatus(Int32)
    case invalidData
}
