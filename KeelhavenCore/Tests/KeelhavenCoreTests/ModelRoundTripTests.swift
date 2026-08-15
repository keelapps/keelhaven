import XCTest
@testable import KeelhavenCore

final class ModelRoundTripTests: XCTestCase {
    // ISO 8601 persistence keeps whole-second precision, so fixed
    // whole-second dates round-trip exactly.
    private let date = Date(timeIntervalSince1970: 1_755_200_000)

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: encoder.encode(value))
    }

    func testBackupPlanRoundTripAllDestinations() throws {
        let destinations: [Destination] = [
            .local(path: "/Volumes/Backup/repo"),
            .s3(S3Config(endpoint: "s3.amazonaws.com", bucket: "b", pathPrefix: "p", accessKeyID: "AKIA")),
            .sftp(SFTPConfig(user: "u", host: "h.local", port: 2222, path: "/data")),
        ]
        for destination in destinations {
            let plan = BackupPlan(
                name: "Documents",
                sourcePaths: ["/Users/me/Documents"],
                destination: destination,
                schedule: .daily(hour: 21, minute: 30),
                createdAt: date,
                lastRun: BackupRunRecord(
                    date: date,
                    success: true,
                    snapshotID: "c4e6a708",
                    filesNew: 308,
                    dataAddedBytes: 400_775_099,
                    duration: 1.62
                )
            )
            XCTAssertEqual(try roundTrip(plan), plan)
        }
    }

    func testScheduleRoundTrip() throws {
        XCTAssertEqual(try roundTrip(Schedule.hourly), .hourly)
        XCTAssertEqual(try roundTrip(Schedule.daily(hour: 3, minute: 15)), .daily(hour: 3, minute: 15))
        XCTAssertEqual(
            try roundTrip(Schedule.weekly(weekday: 6, hour: 8, minute: 30)),
            .weekly(weekday: 6, hour: 8, minute: 30)
        )
    }

    func testFailedRunRecordRoundTrip() throws {
        let record = BackupRunRecord(
            date: date,
            success: false,
            errorMessage: "Fatal: wrong password or no key found"
        )
        XCTAssertEqual(try roundTrip(record), record)
    }
}
