import Foundation

/// Pure due math for retention passes (`restic forget --prune`), kept
/// timer-free like SchedulePolicy and CheckPolicy. Passes ride the tail of a
/// successful backup for the same reasons checks do: the destination is
/// provably reachable and restic is already serialized.
public enum PrunePolicy {
    /// Forget itself is cheap, but `--prune` repacks the repository, which on
    /// a remote destination costs real requests and bandwidth — weekly
    /// reclaims space promptly without turning hourly backups into repacks.
    public static let interval: TimeInterval = 7 * 86400

    /// Due when retention is on and the last pass is at least one interval
    /// old, pass or fail. A plan that has never pruned counts from its
    /// creation date — a brand-new plan has nothing to reclaim and waits a
    /// full week, while turning retention on for an old plan makes the first
    /// pass due at the very next backup.
    public static func isDue(_ plan: BackupPlan, now: Date) -> Bool {
        guard plan.retention != .off else { return false }
        let anchor = plan.lastPrune?.date ?? plan.createdAt
        return anchor.addingTimeInterval(interval) <= now
    }
}
