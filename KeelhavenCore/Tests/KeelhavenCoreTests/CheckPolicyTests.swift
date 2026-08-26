import XCTest
@testable import KeelhavenCore

final class CheckPolicyTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_755_200_000)
    private let week: TimeInterval = 7 * 86400
    private let month: TimeInterval = 30 * 86400

    private func makePlan(
        cadence: CheckCadence,
        lastCheck: CheckRunRecord? = nil
    ) -> BackupPlan {
        BackupPlan(
            name: "Test",
            sourcePaths: ["/tmp/src"],
            destination: .local(path: "/tmp/repo"),
            schedule: .hourly,
            checkCadence: cadence,
            createdAt: created,
            lastCheck: lastCheck
        )
    }

    func testIntervalPerCadence() {
        XCTAssertNil(CheckPolicy.interval(for: .off))
        XCTAssertEqual(CheckPolicy.interval(for: .weekly), week)
        XCTAssertEqual(CheckPolicy.interval(for: .monthly), month)
    }

    func testOffIsNeverDue() {
        let plan = makePlan(cadence: .off)
        XCTAssertFalse(CheckPolicy.isDue(plan, now: created.addingTimeInterval(365 * 86400)))
    }

    func testNeverCheckedPlanCountsFromCreation() {
        // Not due the moment a plan is created — the repository was just
        // initialized or password-proven, so the first check waits a full
        // interval.
        let plan = makePlan(cadence: .weekly)
        XCTAssertFalse(CheckPolicy.isDue(plan, now: created))
        XCTAssertFalse(CheckPolicy.isDue(plan, now: created.addingTimeInterval(week - 1)))
        XCTAssertTrue(CheckPolicy.isDue(plan, now: created.addingTimeInterval(week)))
    }

    func testCheckedPlanCountsFromLastCheck() {
        let checkedAt = created.addingTimeInterval(3 * 86400)
        let plan = makePlan(
            cadence: .weekly,
            lastCheck: CheckRunRecord(date: checkedAt, success: true)
        )
        XCTAssertFalse(CheckPolicy.isDue(plan, now: checkedAt.addingTimeInterval(week - 1)))
        XCTAssertTrue(CheckPolicy.isDue(plan, now: checkedAt.addingTimeInterval(week)))
    }

    func testFailedCheckStillAdvancesTheClock() {
        // A failing repository alerts once per cadence, not after every
        // backup — the anchor is the last attempt, pass or fail.
        let failedAt = created.addingTimeInterval(week)
        let plan = makePlan(
            cadence: .weekly,
            lastCheck: CheckRunRecord(date: failedAt, success: false, errorMessage: "pack corrupted")
        )
        XCTAssertFalse(CheckPolicy.isDue(plan, now: failedAt.addingTimeInterval(86400)))
        XCTAssertTrue(CheckPolicy.isDue(plan, now: failedAt.addingTimeInterval(week)))
    }

    func testMonthlyCadence() {
        let plan = makePlan(
            cadence: .monthly,
            lastCheck: CheckRunRecord(date: created, success: true)
        )
        XCTAssertFalse(CheckPolicy.isDue(plan, now: created.addingTimeInterval(week)))
        XCTAssertTrue(CheckPolicy.isDue(plan, now: created.addingTimeInterval(month)))
    }
}
