import Foundation

/// How much snapshot history a plan keeps — presets rather than free-form
/// keep counts, so retention stays a choice a person can read instead of
/// five numeric fields. `off` means Keelhaven never deletes a snapshot and
/// is the default: deletion is strictly opt-in. The presets map to restic's
/// `forget --keep-*` flags; both keep the three most recent snapshots
/// unconditionally so a burst of runs can never thin away everything recent.
public enum RetentionPolicy: String, Codable, CaseIterable, Hashable, Sendable {
    /// Keep every snapshot.
    case off
    /// About a year of history: 7 daily, 5 weekly, 12 monthly keepers.
    case year
    /// About a month of history: 7 daily, 4 weekly keepers.
    case month

    /// The `restic forget` keep flags for this policy. Empty for `.off`,
    /// which callers must treat as "never run forget" — restic rejects a
    /// forget with no policy rather than deleting anything.
    public var keepArguments: [String] {
        switch self {
        case .off:
            return []
        case .year:
            return [
                "--keep-last", "3",
                "--keep-daily", "7",
                "--keep-weekly", "5",
                "--keep-monthly", "12",
            ]
        case .month:
            return [
                "--keep-last", "3",
                "--keep-daily", "7",
                "--keep-weekly", "4",
            ]
        }
    }
}
