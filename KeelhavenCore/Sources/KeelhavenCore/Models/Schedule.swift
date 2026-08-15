import Foundation

/// When a backup plan should run. Kept deliberately small: hourly, daily,
/// weekly — no monthly (a 30-day loss window is not a backup) and no custom
/// intervals (issue #41).
public enum Schedule: Codable, Hashable, Sendable {
    case hourly
    case daily(hour: Int, minute: Int)
    /// `weekday` follows the Calendar convention: 1 = Sunday … 7 = Saturday.
    case weekly(weekday: Int, hour: Int, minute: Int)
}
