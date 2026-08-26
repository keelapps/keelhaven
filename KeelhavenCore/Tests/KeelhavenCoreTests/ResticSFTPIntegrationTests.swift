import XCTest
@testable import KeelhavenCore

/// End-to-end tests over sftp against a real sshd with the real restic binary
/// — the same path a user's NAS takes. Defaults to the current user on
/// 127.0.0.1:22, which is macOS "Remote Login" (System Settings → General →
/// Sharing); CI enables it on the runner (see .github/workflows/ci.yml).
/// The suite self-skips unless a BatchMode ssh session works, which is the
/// exact precondition restic's sftp backend has in production: it shells out
/// to ssh with no TTY, so host key and key auth must already be in place.
///
/// Overrides (for pointing at a real NAS or a secondary sshd):
/// KEELHAVEN_TEST_SFTP_USER, _HOST, _PORT, _BASE_PATH. A non-22 port also
/// flips SFTPConfig to its sftp://…//absolute URL form, so pointing _PORT at
/// an sshd on another port covers that branch end to end.
final class ResticSFTPIntegrationTests: XCTestCase {
    private var workDirectory: URL!

    override func setUpWithError() throws {
        workDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeelhavenSFTPIntegration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let workDirectory {
            try? FileManager.default.removeItem(at: workDirectory)
        }
    }

    func testFullBackupCycleAndWrongPassword() async throws {
        guard let binary = IntegrationTestSupport.locateRestic() else {
            throw XCTSkip("restic is not installed; run: brew install restic")
        }
        let user = IntegrationTestSupport.environmentValue(
            "KEELHAVEN_TEST_SFTP_USER", default: NSUserName())
        let host = IntegrationTestSupport.environmentValue(
            "KEELHAVEN_TEST_SFTP_HOST", default: "127.0.0.1")
        let port = Int(IntegrationTestSupport.environmentValue(
            "KEELHAVEN_TEST_SFTP_PORT", default: "22")) ?? 22
        guard IntegrationTestSupport.sshIsReachable(user: user, host: host, port: port) else {
            throw XCTSkip("""
                no non-interactive ssh to \(user)@\(host) port \(port); enable Remote Login \
                with key auth and a known_hosts entry, then verify with: \
                ssh -o BatchMode=yes -p \(port) \(user)@\(host) true
                """)
        }

        // The repository path is a path on the *remote* host. The default
        // host is 127.0.0.1 where remote and local filesystem are the same,
        // so the local scratch directory works and gets cleaned up in
        // tearDown; against a real remote host, set _BASE_PATH (the run's
        // repository is left behind there).
        let basePath = IntegrationTestSupport.environmentValue(
            "KEELHAVEN_TEST_SFTP_BASE_PATH", default: workDirectory.path)
        let config = SFTPConfig(
            user: user,
            host: host,
            port: port,
            path: "\(basePath)/repo-\(UUID().uuidString.prefix(8))"
        )
        let destination = Destination.sftp(config)
        let credentials = RepoCredentials(repositoryPassword: "sftp-integration-password")

        try await IntegrationTestSupport.runFullBackupCycle(
            binary: binary,
            destination: destination,
            credentials: credentials,
            workDirectory: workDirectory
        )

        // Wrong repository password must classify the same over sftp as
        // locally (the exit code has to survive the ssh subprocess chain).
        let runner = ResticRunner(binaryURL: binary)
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
    }
}
