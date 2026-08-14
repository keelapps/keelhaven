import Foundation

/// Outcome of a single backup run, kept for history and menu bar display.
public struct BackupRunRecord: Codable, Hashable, Sendable {
    public var date: Date
    public var success: Bool
    public var snapshotID: String?
    public var filesNew: Int?
    public var filesChanged: Int?
    public var dataAddedBytes: Int64?
    public var duration: TimeInterval?
    public var errorMessage: String?

    public init(
        date: Date,
        success: Bool,
        snapshotID: String? = nil,
        filesNew: Int? = nil,
        filesChanged: Int? = nil,
        dataAddedBytes: Int64? = nil,
        duration: TimeInterval? = nil,
        errorMessage: String? = nil
    ) {
        self.date = date
        self.success = success
        self.snapshotID = snapshotID
        self.filesNew = filesNew
        self.filesChanged = filesChanged
        self.dataAddedBytes = dataAddedBytes
        self.duration = duration
        self.errorMessage = errorMessage
    }
}
