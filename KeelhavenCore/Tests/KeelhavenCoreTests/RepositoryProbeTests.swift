import XCTest
@testable import KeelhavenCore

final class RepositoryProbeTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeelhavenProbe-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    func testEmptyPathIsNotARepository() {
        XCTAssertFalse(RepositoryProbe.localPathContainsRepository(""))
    }

    func testFolderWithoutConfigIsNotARepository() {
        XCTAssertFalse(RepositoryProbe.localPathContainsRepository(directory.path))
    }

    func testFolderWithConfigIsARepository() throws {
        try Data("fake".utf8).write(to: directory.appendingPathComponent("config"))
        XCTAssertTrue(RepositoryProbe.localPathContainsRepository(directory.path))
    }

    func testMissingFolderIsNotARepository() {
        XCTAssertFalse(RepositoryProbe.localPathContainsRepository(directory.appendingPathComponent("nope").path))
    }
}
