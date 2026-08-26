import Foundation

/// Outcome of a repository integrity check, kept on the plan for the menu
/// bar and for the next-check due math.
public struct CheckRunRecord: Codable, Hashable, Sendable {
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
