import XCTest
@testable import KeelhavenCore

/// All fixtures are unmodified output captured from restic 0.19.1 on macOS.
final class ResticMessageParsingTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: nil),
            "Missing fixture \(name)"
        )
        return try Data(contentsOf: url)
    }

    private func fixtureLines(_ name: String) throws -> [String] {
        let text = String(decoding: try fixtureData(name), as: UTF8.self)
        return text.split(separator: "\n").map(String.init)
    }

    func testDecodeInitResult() throws {
        let result = try ResticJSON.decoder.decode(ResticInitResult.self, from: fixtureData("init.json"))
        XCTAssertEqual(result.messageType, "initialized")
        XCTAssertEqual(result.id.count, 64)
        XCTAssertTrue(result.repository.hasSuffix("/repo"))
    }

    func testDecodeEveryBackupProgressLine() throws {
        let lines = try fixtureLines("backup-progress.jsonl")
        XCTAssertEqual(lines.count, 10)

        var statusCount = 0
        var summaryCount = 0
        for line in lines {
            let event = try XCTUnwrap(
                ResticJSON.decodeProgressEvent(fromLine: line),
                "Line failed to decode: \(line.prefix(120))"
            )
            switch event {
            case .status(let status):
                statusCount += 1
                XCTAssertGreaterThanOrEqual(status.percentDone, 0)
                XCTAssertLessThanOrEqual(status.percentDone, 1)
            case .summary(let summary):
                summaryCount += 1
                XCTAssertEqual(summary.filesNew, 308)
                XCTAssertEqual(summary.snapshotID?.count, 64)
                XCTAssertNotNil(summary.totalDuration)
                XCTAssertNotNil(summary.backupStart)
                XCTAssertNotNil(summary.backupEnd)
            }
        }
        XCTAssertEqual(statusCount, 9)
        XCTAssertEqual(summaryCount, 1)
    }

    func testStatusFieldOptionality() throws {
        let lines = try fixtureLines("backup-progress.jsonl")
        // The final status line (percent_done == 1) has no current_files;
        // seconds_remaining appears on only some lines.
        let events = lines.compactMap(ResticJSON.decodeProgressEvent(fromLine:))
        let statuses: [BackupStatusMessage] = events.compactMap {
            if case .status(let status) = $0 { return status }
            return nil
        }
        XCTAssertTrue(statuses.contains { $0.currentFiles == nil })
        XCTAssertTrue(statuses.contains { $0.currentFiles != nil })
        XCTAssertTrue(statuses.contains { $0.secondsRemaining != nil })
        XCTAssertTrue(statuses.contains { $0.secondsRemaining == nil })
    }

    func testDecodeIncrementalBackupSummary() throws {
        let lines = try fixtureLines("backup-incremental.jsonl")
        let events = lines.compactMap(ResticJSON.decodeProgressEvent(fromLine:))
        let summaries: [BackupSummary] = events.compactMap {
            if case .summary(let summary) = $0 { return summary }
            return nil
        }
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].filesNew, 1)
        XCTAssertEqual(summaries[0].filesUnmodified, 308)
    }

    func testDecodeSnapshots() throws {
        let snapshots = try ResticJSON.decoder.decode([ResticSnapshot].self, from: fixtureData("snapshots.json"))
        XCTAssertEqual(snapshots.count, 2)

        // First snapshot has no parent; second references the first.
        XCTAssertNil(snapshots[0].parent)
        XCTAssertEqual(snapshots[1].parent, snapshots[0].id)
        XCTAssertEqual(snapshots[0].shortID, String(snapshots[0].id.prefix(8)))
        XCTAssertEqual(snapshots[0].paths.count, 1)

        // Nested summaries lack total_duration and snapshot_id but carry counts.
        let nested = try XCTUnwrap(snapshots[0].summary)
        XCTAssertEqual(nested.filesNew, 308)
        XCTAssertNil(nested.totalDuration)
        XCTAssertNil(nested.snapshotID)

        // Timestamps with fractional seconds and zone offset parse correctly.
        XCTAssertLessThan(snapshots[0].time, snapshots[1].time)
    }

    func testDecodeRepoConfig() throws {
        // Captured from `restic cat config --json`; a successful decode is
        // how adopting an existing repository verifies its password.
        let config = try ResticJSON.decoder.decode(ResticRepoConfig.self, from: fixtureData("cat-config.json"))
        XCTAssertEqual(config.version, 2)
        XCTAssertEqual(config.id.count, 64)
    }

    func testDecodeStats() throws {
        let stats = try ResticJSON.decoder.decode(ResticStats.self, from: fixtureData("stats.json"))
        XCTAssertEqual(stats.snapshotsCount, 2)
        XCTAssertEqual(stats.totalFileCount, 633)
        XCTAssertGreaterThan(stats.totalSize, 0)
    }

    func testClassifyWrongPasswordFromRealStderr() throws {
        let stderr = String(decoding: try fixtureData("error-wrong-password.json"), as: UTF8.self)
        // Exit code 12 observed from restic 0.19.1 for wrong password.
        let error = ResticError.classify(exitCode: 12, stderr: stderr)
        guard case .wrongPassword(let message) = error else {
            return XCTFail("Expected wrongPassword, got \(error)")
        }
        XCTAssertTrue(message.contains("wrong password"))
        XCTAssertFalse(message.contains("message_type"), "Should surface the inner message, not raw JSON")
    }

    func testClassifyMissingRepositoryFromRealStderr() throws {
        let stderr = String(decoding: try fixtureData("error-no-repo.json"), as: UTF8.self)
        // Exit code 10 observed from restic 0.19.1 for missing repository.
        let error = ResticError.classify(exitCode: 10, stderr: stderr)
        guard case .repositoryDoesNotExist(let message) = error else {
            return XCTFail("Expected repositoryDoesNotExist, got \(error)")
        }
        XCTAssertTrue(message.contains("repository does not exist"))
    }

    func testClassifyRepositoryAlreadyExistsFromRealStderr() throws {
        // Captured from `restic init` against a folder already holding a repo
        // (exit code 1). Note restic's own doubled "Fatal: Fatal:" prefix.
        let stderr = String(decoding: try fixtureData("error-repo-exists.json"), as: UTF8.self)
        let error = ResticError.classify(exitCode: 1, stderr: stderr)
        guard case .repositoryAlreadyExists(let message) = error else {
            return XCTFail("Expected repositoryAlreadyExists, got \(error)")
        }
        XCTAssertFalse(message.hasPrefix("Fatal:"), "Fatal: prefixes should be stripped")
        XCTAssertTrue(message.contains("config file already exists"))
    }

    func testClassifyStripsFatalPrefixes() throws {
        let stderr = String(decoding: try fixtureData("error-wrong-password.json"), as: UTF8.self)
        let error = ResticError.classify(exitCode: 12, stderr: stderr)
        guard case .wrongPassword(let message) = error else {
            return XCTFail("Expected wrongPassword, got \(error)")
        }
        XCTAssertEqual(message, "wrong password or no key found")
    }

    func testClassifyUnknownExitCodeFallsBack() {
        let error = ResticError.classify(exitCode: 1, stderr: "some plain text failure")
        XCTAssertEqual(error, .commandFailed(exitCode: 1, message: "some plain text failure"))
    }

    func testNonProgressLinesAreIgnored() {
        XCTAssertNil(ResticJSON.decodeProgressEvent(fromLine: ""))
        XCTAssertNil(ResticJSON.decodeProgressEvent(fromLine: "not json"))
        XCTAssertNil(ResticJSON.decodeProgressEvent(fromLine: #"{"message_type":"verbose_status","action":"scan"}"#))
    }
}
