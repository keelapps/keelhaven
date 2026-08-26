import Foundation

/// Pure due math for scheduled repository checks (`restic check`), kept
/// timer-free like SchedulePolicy. Checks are interval-based rather than
/// wall-clock — "at least once a week", not "Sundays at 09:00" — and the app
/// runs them on the tail of a successful backup, so the destination is known
/// reachable and the two restic invocations can never contend for the
/// repository lock.
public enum CheckPolicy {
    /// Seconds between checks, or nil when checks are off.
    public static func interval(for cadence: CheckCadence) -> TimeInterval? {
        switch cadence {
        case .off:
            return nil
        case .weekly:
            return 7 * 86400
        case .monthly:
            return 30 * 86400
        }
    }

    /// Due when checking is on and the last check is at least one interval
    /// old. The clock counts from the last check whether it passed or failed,
    /// so a corrupt repository alerts once per cadence instead of after every
    /// backup. A plan that has never been checked counts from its creation
    /// date: the repository was created (or adopted, password-proven) moments
    /// before, so the first verification can wait a full interval.
    public static func isDue(_ plan: BackupPlan, now: Date) -> Bool {
        guard let interval = interval(for: plan.checkCadence) else {
            return false
        }
        let anchor = plan.lastCheck?.date ?? plan.createdAt
        return anchor.addingTimeInterval(interval) <= now
    }
}
