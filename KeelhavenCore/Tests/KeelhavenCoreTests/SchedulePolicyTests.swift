import XCTest
@testable import KeelhavenCore

final class SchedulePolicyTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func utcDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components)!
    }

    private func makePlan(schedule: Schedule, lastRun: Date?) -> BackupPlan {
        BackupPlan(
            name: "Test",
            sourcePaths: ["/tmp/src"],
            destination: .local(path: "/tmp/repo"),
            schedule: schedule,
            lastRun: lastRun.map { BackupRunRecord(date: $0, success: true) }
        )
    }

    func testHourlyNextRun() {
        let reference = utcDate(2026, 8, 14, 10, 30)
        let next = SchedulePolicy.nextRun(for: .hourly, after: reference, calendar: calendar)
        XCTAssertEqual(next, utcDate(2026, 8, 14, 11, 30))
    }

    func testDailyNextRunLaterSameDay() {
        let reference = utcDate(2026, 8, 14, 10, 0)
        let next = SchedulePolicy.nextRun(for: .daily(hour: 21, minute: 30), after: reference, calendar: calendar)
        XCTAssertEqual(next, utcDate(2026, 8, 14, 21, 30))
    }

    func testDailyNextRunRollsToTomorrow() {
        let reference = utcDate(2026, 8, 14, 22, 0)
        let next = SchedulePolicy.nextRun(for: .daily(hour: 21, minute: 30), after: reference, calendar: calendar)
        XCTAssertEqual(next, utcDate(2026, 8, 15, 21, 30))
    }

    func testNeverRanPlanIsDue() {
        let plan = makePlan(schedule: .hourly, lastRun: nil)
        XCTAssertTrue(SchedulePolicy.isDue(plan, now: utcDate(2026, 8, 14, 0, 0), calendar: calendar))
    }

    func testHourlyPlanNotDueBeforeInterval() {
        let plan = makePlan(schedule: .hourly, lastRun: utcDate(2026, 8, 14, 10, 0))
        XCTAssertFalse(SchedulePolicy.isDue(plan, now: utcDate(2026, 8, 14, 10, 59), calendar: calendar))
        XCTAssertTrue(SchedulePolicy.isDue(plan, now: utcDate(2026, 8, 14, 11, 0), calendar: calendar))
    }

    func testMissedDailyRunIsDueImmediately() {
        // Last ran Monday 21:30; Mac was asleep Tuesday; Wednesday morning it's overdue.
        let plan = makePlan(schedule: .daily(hour: 21, minute: 30), lastRun: utcDate(2026, 8, 10, 21, 30))
        XCTAssertTrue(SchedulePolicy.isDue(plan, now: utcDate(2026, 8, 12, 9, 0), calendar: calendar))
    }

    func testDailyRunNotDueTwiceInSameWindow() {
        let plan = makePlan(schedule: .daily(hour: 21, minute: 30), lastRun: utcDate(2026, 8, 14, 21, 30))
        XCTAssertFalse(SchedulePolicy.isDue(plan, now: utcDate(2026, 8, 14, 23, 0), calendar: calendar))
        XCTAssertTrue(SchedulePolicy.isDue(plan, now: utcDate(2026, 8, 15, 21, 30), calendar: calendar))
    }
}
