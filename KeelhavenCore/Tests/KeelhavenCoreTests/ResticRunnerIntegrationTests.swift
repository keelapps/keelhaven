import XCTest
@testable import KeelhavenCore

/// End-to-end tests against a real restic binary. Skipped when restic is not
/// installed, so `swift test` stays green on bare CI machines.
final class ResticRunnerIntegrationTests: XCTestCase {
    private var workDirectory: URL!

    override func setUpWithError() throws {
        workDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeelhavenIntegration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let workDirectory {
            try? FileManager.default.removeItem(at: workDirectory)
        }
    }

    func testInitBackupSnapshotsAndErrorClassification() async throws {
        guard let binary = IntegrationTestSupport.locateRestic() else {
            throw XCTSkip("restic is not installed; run: brew install restic")
        }

        let repoURL = workDirectory.appendingPathComponent("repo", isDirectory: true)
        let sourceURL = workDirectory.appendingPathComponent("src", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceURL, withIntermediateDirectories: true)
        for index in 0..<20 {
            let file = sourceURL.appendingPathComponent("file\(index).txt")
            try Data("hello keelhaven \(index)\n".utf8).write(to: file)
        }

        let destination = Destination.local(path: repoURL.path)
        let credentials = RepoCredentials(repositoryPassword: "integration-test-password")
        let runner = ResticRunner(binaryURL: binary)

        // init
        let initResult = try await runner.run(
            .initRepository,
            destination: destination,
            credentials: credentials,
            decoding: ResticInitResult.self
        )
        XCTAssertEqual(initResult.messageType, "initialized")
        XCTAssertEqual(initResult.repository, repoURL.path)

        // streaming backup: must yield exactly one summary carrying a snapshot id
        var summary: BackupSummary?
        let stream = runner.backupStream(
            .backup(sources: [sourceURL.path], excludes: [".DS_Store"], tag: "keelhaven-test"),
            destination: destination,
            credentials: credentials
        )
        for try await event in stream {
            if case .summary(let value) = event {
                XCTAssertNil(summary, "More than one summary event")
                summary = value
            }
        }
        let snapshotID = try XCTUnwrap(summary?.snapshotID)
        XCTAssertEqual(summary?.filesNew, 20)

        // snapshots: sees exactly the snapshot the backup reported
        let snapshots = try await runner.run(
            .snapshots,
            destination: destination,
            credentials: credentials,
            decoding: [ResticSnapshot].self
        )
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].id, snapshotID)

        // cat config with the right password: how adoption verifies a repo
        let config = try await runner.run(
            .catConfig,
            destination: destination,
            credentials: credentials,
            decoding: ResticRepoConfig.self
        )
        XCTAssertEqual(config.version, 2)
        XCTAssertEqual(config.id.count, 64)

        // restore the snapshot into a fresh target and verify the files
        let restoreTarget = workDirectory.appendingPathComponent("restored", isDirectory: true)
        var restoreSummary: RestoreSummary?
        let restoreEvents = runner.restoreStream(
            .restore(snapshotID: snapshotID, target: restoreTarget.path),
            destination: destination,
            credentials: credentials
        )
        for try await event in restoreEvents {
            if case .summary(let value) = event {
                restoreSummary = value
            }
        }
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(restoreSummary).filesRestored, 20)
        // restic recreates the absolute source path inside the target
        let restoredFile = restoreTarget.appendingPathComponent(sourceURL.path)
            .appendingPathComponent("file0.txt")
        XCTAssertEqual(
            try String(contentsOf: restoredFile, encoding: .utf8),
            "hello keelhaven 0\n"
        )

        // wrong password → typed error from the real exit code
        do {
            _ = try await runner.run(
                .snapshots,
                destination: destination,
                credentials: RepoCredentials(repositoryPassword: "wrong"),
                decoding: [ResticSnapshot].self
            )
            XCTFail("Expected wrongPassword error")
        } catch let error as ResticError {
            guard case .wrongPassword = error else {
                return XCTFail("Expected wrongPassword, got \(error)")
            }
        }

        // missing repository → typed error
        let missing = Destination.local(path: workDirectory.appendingPathComponent("nope").path)
        do {
            _ = try await runner.run(
                .snapshots,
                destination: missing,
                credentials: credentials,
                decoding: [ResticSnapshot].self
            )
            XCTFail("Expected repositoryDoesNotExist error")
        } catch let error as ResticError {
            guard case .repositoryDoesNotExist = error else {
                return XCTFail("Expected repositoryDoesNotExist, got \(error)")
            }
        }
    }

    func testMissingBinaryThrowsBinaryNotFound() async {
        let runner = ResticRunner(binaryURL: URL(fileURLWithPath: "/nonexistent/restic"))
        do {
            _ = try await runner.run(
                .snapshots,
                destination: .local(path: "/tmp"),
                credentials: RepoCredentials(repositoryPassword: "x"),
                decoding: [ResticSnapshot].self
            )
            XCTFail("Expected binaryNotFound")
        } catch let error as ResticError {
            XCTAssertEqual(error, .binaryNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
