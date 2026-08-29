import XCTest
@testable import KeelhavenCore

final class PrunePolicyTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_755_200_000)
    private let week: TimeInterval = 7 * 86400

    private func makePlan(
        retention: RetentionPolicy,
        lastPrune: PruneRunRecord? = nil
    ) -> BackupPlan {
        BackupPlan(
            name: "Test",
            sourcePaths: ["/tmp/src"],
            destination: .local(path: "/tmp/repo"),
            schedule: .hourly,
            retention: retention,
            createdAt: created,
            lastPrune: lastPrune
        )
    }

    func testOffIsNeverDue() {
        let plan = makePlan(retention: .off)
        XCTAssertFalse(PrunePolicy.isDue(plan, now: created.addingTimeInterval(365 * 86400)))
    }

    func testNewPlanWaitsAFullInterval() {
        // A brand-new plan has nothing to reclaim, so the first pass waits a
        // week from creation.
        let plan = makePlan(retention: .year)
        XCTAssertFalse(PrunePolicy.isDue(plan, now: created))
        XCTAssertFalse(PrunePolicy.isDue(plan, now: created.addingTimeInterval(week - 1)))
        XCTAssertTrue(PrunePolicy.isDue(plan, now: created.addingTimeInterval(week)))
    }

    func testPrunedPlanCountsFromLastPass() {
        let prunedAt = created.addingTimeInterval(3 * 86400)
        let plan = makePlan(
            retention: .month,
            lastPrune: PruneRunRecord(date: prunedAt, success: true)
        )
        XCTAssertFalse(PrunePolicy.isDue(plan, now: prunedAt.addingTimeInterval(week - 1)))
        XCTAssertTrue(PrunePolicy.isDue(plan, now: prunedAt.addingTimeInterval(week)))
    }

    func testFailedPassStillAdvancesTheClock() {
        // A destination that keeps failing prunes retries weekly, not after
        // every backup — the anchor is the last attempt, pass or fail.
        let failedAt = created.addingTimeInterval(week)
        let plan = makePlan(
            retention: .year,
            lastPrune: PruneRunRecord(date: failedAt, success: false, errorMessage: "repository is locked")
        )
        XCTAssertFalse(PrunePolicy.isDue(plan, now: failedAt.addingTimeInterval(86400)))
        XCTAssertTrue(PrunePolicy.isDue(plan, now: failedAt.addingTimeInterval(week)))
    }
}
