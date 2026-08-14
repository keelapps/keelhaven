import Foundation

/// Append-only backup run history, one capped list per plan, stored as JSON
/// next to plans.json.
public actor RunHistoryStore {
    public static let maxRecordsPerPlan = 100

    private let fileURL: URL

    public init(directory: URL = PlanStore.defaultDirectory()) {
        self.fileURL = directory.appendingPathComponent("runs.json")
    }

    public func history(for planID: UUID) throws -> [BackupRunRecord] {
        try loadAll()[planID.uuidString] ?? []
    }

    public func append(_ record: BackupRunRecord, planID: UUID) throws {
        var all = try loadAll()
        var records = all[planID.uuidString] ?? []
        records.append(record)
        if records.count > Self.maxRecordsPerPlan {
            records.removeFirst(records.count - Self.maxRecordsPerPlan)
        }
        all[planID.uuidString] = records
        try save(all)
    }

    public func deleteHistory(for planID: UUID) throws {
        var all = try loadAll()
        all.removeValue(forKey: planID.uuidString)
        try save(all)
    }

    private func loadAll() throws -> [String: [BackupRunRecord]] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [:]
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([String: [BackupRunRecord]].self, from: data)
    }

    private func save(_ all: [String: [BackupRunRecord]]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(all)
        try data.write(to: fileURL, options: .atomic)
    }
}
