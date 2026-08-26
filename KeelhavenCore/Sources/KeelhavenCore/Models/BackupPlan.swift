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
    public var checkCadence: CheckCadence
    public var createdAt: Date
    public var lastRun: BackupRunRecord?
    public var lastCheck: CheckRunRecord?

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
        checkCadence: CheckCadence = .weekly,
        createdAt: Date = Date(),
        lastRun: BackupRunRecord? = nil,
        lastCheck: CheckRunRecord? = nil
    ) {
        self.id = id
        self.name = name
        self.sourcePaths = sourcePaths
        self.destination = destination
        self.schedule = schedule
        self.excludePatterns = excludePatterns
        self.checkCadence = checkCadence
        self.createdAt = createdAt
        self.lastRun = lastRun
        self.lastCheck = lastCheck
    }

    /// Plans saved before scheduled checks existed lack the two check keys —
    /// decode them leniently so an upgrade can never lose the plan list.
    /// (`encode(to:)` and `CodingKeys` stay synthesized.)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sourcePaths = try container.decode([String].self, forKey: .sourcePaths)
        destination = try container.decode(Destination.self, forKey: .destination)
        schedule = try container.decode(Schedule.self, forKey: .schedule)
        excludePatterns = try container.decode([String].self, forKey: .excludePatterns)
        checkCadence = try container.decodeIfPresent(CheckCadence.self, forKey: .checkCadence) ?? .weekly
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastRun = try container.decodeIfPresent(BackupRunRecord.self, forKey: .lastRun)
        lastCheck = try container.decodeIfPresent(CheckRunRecord.self, forKey: .lastCheck)
    }
}
