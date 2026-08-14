import Foundation

/// Pure schedule math, kept free of timers and app state so it is fully
/// unit-testable. The app's timer asks `isDue` about once a minute.
public enum SchedulePolicy {
    public static func nextRun(
        for schedule: Schedule,
        after reference: Date,
        calendar: Calendar = .current
    ) -> Date {
        switch schedule {
        case .hourly:
            return reference.addingTimeInterval(3600)
        case .daily(let hour, let minute):
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = 0
            return calendar.nextDate(
                after: reference,
                matching: components,
                matchingPolicy: .nextTime
            ) ?? reference.addingTimeInterval(86400)
        }
    }

    /// A plan is due when it has never run, or when its next scheduled time
    /// after the last run is in the past. Missed runs (Mac was asleep or the
    /// app wasn't running) therefore make the plan due immediately.
    public static func isDue(
        _ plan: BackupPlan,
        now: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard let lastRunDate = plan.lastRun?.date else {
            return true
        }
        return nextRun(for: plan.schedule, after: lastRunDate, calendar: calendar) <= now
    }
}
