import XCTest
@testable import KeelhavenCore

final class PlanStorePersistenceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeelhavenTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    func testLoadFromEmptyDirectoryReturnsNoPlans() async throws {
        let store = PlanStore(directory: directory)
        let plans = try await store.load()
        XCTAssertEqual(plans, [])
    }

    func testSaveAndLoadRoundTrip() async throws {
        let store = PlanStore(directory: directory)
        let plan = BackupPlan(
            name: "Documents",
            sourcePaths: ["/Users/me/Documents"],
            destination: .local(path: "/Volumes/Backup/repo"),
            schedule: .daily(hour: 21, minute: 0),
            createdAt: Date(timeIntervalSince1970: 1_755_200_000)
        )
        try await store.save([plan])

        let reloaded = PlanStore(directory: directory)
        let plans = try await reloaded.load()
        XCTAssertEqual(plans, [plan])
    }

    func testSaveOverwritesPreviousContents() async throws {
        let store = PlanStore(directory: directory)
        let first = BackupPlan(
            name: "First",
            sourcePaths: ["/a"],
            destination: .local(path: "/repo1"),
            schedule: .hourly,
            createdAt: Date(timeIntervalSince1970: 1_755_200_000)
        )
        try await store.save([first])
        try await store.save([])
        let plans = try await store.load()
        XCTAssertEqual(plans, [])
    }

    func testRunHistoryAppendAndCap() async throws {
        let store = RunHistoryStore(directory: directory)
        let planID = UUID()
        let base = Date(timeIntervalSince1970: 1_755_200_000)

        for index in 0..<(RunHistoryStore.maxRecordsPerPlan + 5) {
            let record = BackupRunRecord(date: base.addingTimeInterval(Double(index)), success: true)
            try await store.append(record, planID: planID)
        }

        let history = try await store.history(for: planID)
        XCTAssertEqual(history.count, RunHistoryStore.maxRecordsPerPlan)
        // Oldest entries were dropped; the newest survives.
        XCTAssertEqual(history.last?.date, base.addingTimeInterval(Double(RunHistoryStore.maxRecordsPerPlan + 4)))
    }
}
