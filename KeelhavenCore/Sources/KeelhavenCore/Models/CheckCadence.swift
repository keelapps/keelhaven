import Foundation

/// How often a plan's repository is verified with `restic check`.
/// Deliberately coarser than backup schedules: a check reads repository
/// metadata, which on a remote destination costs requests and bandwidth,
/// and its job is catching silent corruption — weekly is plenty.
public enum CheckCadence: String, Codable, CaseIterable, Hashable, Sendable {
    case off
    case weekly
    case monthly
}
