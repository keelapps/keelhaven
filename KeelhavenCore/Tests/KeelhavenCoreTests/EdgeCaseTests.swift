import XCTest
@testable import KeelhavenCore

final class ResticErrorDescriptionTests: XCTestCase {
    func testClassifyMapsExitCode11ToRepositoryLocked() {
        let error = ResticError.classify(exitCode: 11, stderr: "Fatal: repo already locked")
        XCTAssertEqual(error, .repositoryLocked(message: "repo already locked"))
    }

    func testEveryCaseHasAnActionableDescription() {
        let cases: [(ResticError, String)] = [
            (.binaryNotFound, "could not be found"),
            (.repositoryDoesNotExist(message: "m"), "was not found"),
            (.repositoryAlreadyExists(message: "m"), "already contains a backup repository"),
            (.repositoryLocked(message: "m"), "locked by another process"),
            (.wrongPassword(message: "m"), "password is incorrect"),
            (.commandFailed(exitCode: 3, message: "m"), "exit code 3"),
            (.outputDecodingFailed(message: "m"), "restic's output"),
        ]
        for (error, expectedFragment) in cases {
            let description = error.localizedDescription
            XCTAssertTrue(
                description.contains(expectedFragment),
                "\(error) description missing “\(expectedFragment)”: \(description)"
            )
        }
    }
}

final class ResticDateDecodingTests: XCTestCase {
    func testUnrecognizedDateThrows() {
        let json = Data(#"{"when":"not-a-date"}"#.utf8)
        XCTAssertThrowsError(
            try ResticJSON.decoder.decode([String: Date].self, from: json)
        ) { error in
            guard case DecodingError.dataCorrupted = error else {
                return XCTFail("Expected dataCorrupted, got \(error)")
            }
        }
    }
}

final class DestinationDisplayNameTests: XCTestCase {
    func testDisplayNamesForAllDestinationTypes() {
        XCTAssertEqual(Destination.local(path: "/Volumes/Backup").displayName, "/Volumes/Backup")
        XCTAssertEqual(
            Destination.s3(S3Config(
                endpoint: "s3.amazonaws.com", bucket: "mybucket", pathPrefix: "", accessKeyID: "k"
            )).displayName,
            "s3://mybucket"
        )
        XCTAssertEqual(
            Destination.sftp(SFTPConfig(user: "sxp", host: "nas.local", path: "/backups")).displayName,
            "sxp@nas.local"
        )
    }
}

final class ResticCommandExtraTests: XCTestCase {
    func testStatsAndCheckArguments() {
        XCTAssertEqual(ResticCommand.stats.arguments, ["stats", "--json"])
        XCTAssertEqual(ResticCommand.check.arguments, ["check"])
    }
}

final class StoreEdgeTests: XCTestCase {
    func testDefaultDirectoryIsKeelhavenInApplicationSupport() {
        let directory = PlanStore.defaultDirectory()
        XCTAssertEqual(directory.lastPathComponent, "Keelhaven")
        XCTAssertTrue(directory.path.contains("Application Support"))
    }

    func testDeleteHistoryRemovesOnlyThatPlan() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeelhavenHistory-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = RunHistoryStore(directory: directory)
        let kept = UUID()
        let deleted = UUID()
        try await store.append(BackupRunRecord(date: Date(), success: true), planID: kept)
        try await store.append(BackupRunRecord(date: Date(), success: false), planID: deleted)

        try await store.deleteHistory(for: deleted)

        let keptRecords = try await store.history(for: kept)
        let deletedRecords = try await store.history(for: deleted)
        XCTAssertEqual(keptRecords.count, 1)
        XCTAssertTrue(deletedRecords.isEmpty)
    }
}
