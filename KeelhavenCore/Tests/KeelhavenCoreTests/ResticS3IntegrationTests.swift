import XCTest
@testable import KeelhavenCore

/// End-to-end tests against a real S3-compatible server with the real restic
/// binary — the same path a user's MinIO-on-NAS or cloud bucket takes. CI
/// starts a MinIO server for these (see .github/workflows/ci.yml); locally:
///
///   brew install minio/stable/minio
///   MINIO_ROOT_USER=keelhaven-test MINIO_ROOT_PASSWORD=keelhaven-test-secret \
///     minio server --address 127.0.0.1:9000 /tmp/minio-data
///
/// Overrides (for pointing at another server, e.g. real cloud storage):
/// KEELHAVEN_TEST_S3_ENDPOINT, _ACCESS_KEY, _SECRET_KEY, _BUCKET.
final class ResticS3IntegrationTests: XCTestCase {
    private var workDirectory: URL!

    override func setUpWithError() throws {
        workDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeelhavenS3Integration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let workDirectory {
            try? FileManager.default.removeItem(at: workDirectory)
        }
    }

    func testFullBackupCycleAndCredentialErrors() async throws {
        guard let binary = IntegrationTestSupport.locateRestic() else {
            throw XCTSkip("restic is not installed; run: brew install restic")
        }
        let endpoint = IntegrationTestSupport.environmentValue(
            "KEELHAVEN_TEST_S3_ENDPOINT", default: "http://127.0.0.1:9000")
        guard await IntegrationTestSupport.httpEndpointIsReachable(endpoint) else {
            throw XCTSkip("no S3-compatible server at \(endpoint); start MinIO (see this file's header)")
        }

        // The bucket is created by the first `restic init` and reused across
        // runs; the unique prefix keeps runs isolated and exercises
        // S3Config.pathPrefix end to end.
        let config = S3Config(
            endpoint: endpoint,
            bucket: IntegrationTestSupport.environmentValue(
                "KEELHAVEN_TEST_S3_BUCKET", default: "keelhaven-integration"),
            pathPrefix: "run-\(UUID().uuidString.prefix(8))",
            accessKeyID: IntegrationTestSupport.environmentValue(
                "KEELHAVEN_TEST_S3_ACCESS_KEY", default: "keelhaven-test")
        )
        let destination = Destination.s3(config)
        let credentials = RepoCredentials(
            repositoryPassword: "s3-integration-password",
            s3SecretAccessKey: IntegrationTestSupport.environmentValue(
                "KEELHAVEN_TEST_S3_SECRET_KEY", default: "keelhaven-test-secret")
        )

        try await IntegrationTestSupport.runFullBackupCycle(
            binary: binary,
            destination: destination,
            credentials: credentials,
            workDirectory: workDirectory
        )

        let runner = ResticRunner(binaryURL: binary)

        // Wrong repository password must classify the same over S3 as locally
        // (the exit code has to survive the network backend).
        do {
            _ = try await runner.run(
                .snapshots,
                destination: destination,
                credentials: RepoCredentials(
                    repositoryPassword: "wrong",
                    s3SecretAccessKey: credentials.s3SecretAccessKey),
                decoding: [ResticSnapshot].self
            )
            XCTFail("Expected wrongPassword error")
        } catch let error as ResticError {
            guard case .wrongPassword = error else {
                return XCTFail("Expected wrongPassword, got \(error)")
            }
        }

        // Deliberately NOT tested: a wrong S3 secret key. restic 0.19 treats
        // the 403 as a retryable backend error and retries with backoff for
        // up to ~15 minutes before failing, which no test suite can afford to
        // wait out — and which means the app currently shows nothing for that
        // long when a user typos their key. Tracked as a product issue, not a
        // test gap.
    }
}
