import Foundation

/// Loads and saves the plan list as JSON in Application Support (or a custom
/// directory, used by tests). Writes are atomic; secrets never pass through here.
public actor PlanStore {
    private let fileURL: URL

    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Keelhaven", isDirectory: true)
    }

    public init(directory: URL = PlanStore.defaultDirectory()) {
        self.fileURL = directory.appendingPathComponent("plans.json")
    }

    public func load() throws -> [BackupPlan] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode([BackupPlan].self, from: data)
    }

    public func save(_ plans: [BackupPlan]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(plans)
        try data.write(to: fileURL, options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
