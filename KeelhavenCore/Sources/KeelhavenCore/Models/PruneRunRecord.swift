import Foundation

/// Outcome of a retention pass (`restic forget --prune`), kept on the plan
/// for the next-pass due math and for troubleshooting.
public struct PruneRunRecord: Codable, Hashable, Sendable {
    public var date: Date
    public var success: Bool
    public var duration: TimeInterval?
    public var errorMessage: String?

    public init(
        date: Date,
        success: Bool,
        duration: TimeInterval? = nil,
        errorMessage: String? = nil
    ) {
        self.date = date
        self.success = success
        self.duration = duration
        self.errorMessage = errorMessage
    }
}
