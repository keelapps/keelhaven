import Foundation

/// Outcome of a retention pass (`restic forget --prune`), kept on the plan
/// for the next-pass due math and for troubleshooting.
public struct PruneRunRecord: Codable, Hashable, Sendable {
    public var date: Date
    public var success: Bool
    public var duration: TimeInterval?
    public var errorMessage: String?
    /// Set when the pass failed because the repository was locked — the one
    /// prune failure that never clears itself. `forget --prune` needs an
    /// exclusive lock, so a lock left behind by an interrupted run blocks it
    /// forever, while plain backups carry on unaffected (they share a
    /// non-exclusive lock). Optional so plans written before this field
    /// decode unchanged.
    public var blockedByLock: Bool?

    public init(
        date: Date,
        success: Bool,
        duration: TimeInterval? = nil,
        errorMessage: String? = nil,
        blockedByLock: Bool? = nil
    ) {
        self.date = date
        self.success = success
        self.duration = duration
        self.errorMessage = errorMessage
        self.blockedByLock = blockedByLock
    }
}
