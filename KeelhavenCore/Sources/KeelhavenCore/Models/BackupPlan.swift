import Foundation

/// A configured backup: what to back up, where to, and when.
/// Secrets (repository password, S3 secret key) are stored in the Keychain,
/// keyed by this plan's `id` — never in this struct.
public struct BackupPlan: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    /// Absolute paths of the folders to back up.
    public var sourcePaths: [String]
    public var destination: Destination
    public var schedule: Schedule
    public var excludePatterns: [String]
    public var createdAt: Date
    public var lastRun: BackupRunRecord?

    public static let defaultExcludePatterns: [String] = [
        ".DS_Store",
        ".Trash",
        "node_modules",
        "*.tmp",
    ]

    public init(
        id: UUID = UUID(),
        name: String,
        sourcePaths: [String],
        destination: Destination,
        schedule: Schedule,
        excludePatterns: [String] = BackupPlan.defaultExcludePatterns,
        createdAt: Date = Date(),
        lastRun: BackupRunRecord? = nil
    ) {
        self.id = id
        self.name = name
        self.sourcePaths = sourcePaths
        self.destination = destination
        self.schedule = schedule
        self.excludePatterns = excludePatterns
        self.createdAt = createdAt
        self.lastRun = lastRun
    }
}
