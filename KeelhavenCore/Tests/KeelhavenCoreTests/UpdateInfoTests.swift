import XCTest
@testable import KeelhavenCore

final class UpdateInfoTests: XCTestCase {
    // MARK: - SemanticVersion.isNewer

    func testEqualVersionsAreNotNewer() {
        XCTAssertFalse(SemanticVersion.isNewer("1.2.3", than: "1.2.3"))
    }

    func testHigherPatchIsNewer() {
        XCTAssertTrue(SemanticVersion.isNewer("1.2.4", than: "1.2.3"))
    }

    func testHigherMinorIsNewer() {
        XCTAssertTrue(SemanticVersion.isNewer("1.3.0", than: "1.2.9"))
    }

    func testHigherMajorIsNewer() {
        XCTAssertTrue(SemanticVersion.isNewer("2.0.0", than: "1.9.9"))
    }

    func testLowerVersionIsNotNewer() {
        XCTAssertFalse(SemanticVersion.isNewer("1.9.9", than: "2.0.0"))
    }

    func testMissingTrailingComponentsCountAsZero() {
        XCTAssertFalse(SemanticVersion.isNewer("1.2", than: "1.2.0"))
        XCTAssertTrue(SemanticVersion.isNewer("1.2.1", than: "1.2"))
    }

    func testMalformedRemoteVersionIsNeverNewer() {
        XCTAssertFalse(SemanticVersion.isNewer("not-a-version", than: "1.0.0"))
    }

    func testMalformedLocalVersionIsNeverNewer() {
        XCTAssertFalse(SemanticVersion.isNewer("1.0.0", than: "not-a-version"))
    }

    func testEmptyStringsAreNeverNewer() {
        XCTAssertFalse(SemanticVersion.isNewer("", than: ""))
    }

    // MARK: - UpdateInfo round trip

    func testUpdateInfoRoundTrip() throws {
        let info = UpdateInfo(version: "1.2.3", dmgURL: URL(string: "https://keelhaven.app/downloads/Keelhaven-1.2.3.dmg")!)
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(UpdateInfo.self, from: data)
        XCTAssertEqual(decoded, info)
    }

    func testUpdateInfoDecodesLatestJSONShape() throws {
        let json = """
        {"version": "1.2.3", "dmgURL": "https://keelhaven.app/downloads/Keelhaven-1.2.3.dmg"}
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(UpdateInfo.self, from: json)
        XCTAssertEqual(info.version, "1.2.3")
        XCTAssertEqual(info.dmgURL.absoluteString, "https://keelhaven.app/downloads/Keelhaven-1.2.3.dmg")
    }
}
