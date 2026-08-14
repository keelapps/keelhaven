import Foundation

/// When a backup plan should run. Kept deliberately small for v1.
public enum Schedule: Codable, Hashable, Sendable {
    case hourly
    case daily(hour: Int, minute: Int)
}
