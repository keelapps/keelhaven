import XCTest
@testable import KeelhavenCore

final class ResticCommandTests: XCTestCase {
    func testInitArguments() {
        XCTAssertEqual(ResticCommand.initRepository.arguments, ["init", "--json"])
    }

    func testBackupArguments() {
        let command = ResticCommand.backup(
            sources: ["/Users/me/Documents", "/Users/me/Photos"],
            excludes: [".DS_Store", "node_modules"],
            tag: "keelhaven"
        )
        XCTAssertEqual(command.arguments, [
            "backup", "--json",
            "--exclude", ".DS_Store",
            "--exclude", "node_modules",
            "--tag", "keelhaven",
            "/Users/me/Documents", "/Users/me/Photos",
        ])
    }

    func testBackupWithoutTagOrExcludes() {
        let command = ResticCommand.backup(sources: ["/tmp/data"], excludes: [], tag: nil)
        XCTAssertEqual(command.arguments, ["backup", "--json", "/tmp/data"])
    }

    /// No `--remove-all`: that would also drop the exclusive locks
    /// `forget --prune` holds, turning a recovery into a way to corrupt a
    /// concurrent repack.
    func testUnlockArguments() {
        XCTAssertEqual(ResticCommand.unlock.arguments, ["unlock"])
    }

    func testCatConfigArguments() {
        XCTAssertEqual(ResticCommand.catConfig.arguments, ["cat", "config", "--json"])
    }

    func testForgetArguments() {
        XCTAssertEqual(ResticCommand.forget(retention: .year).arguments, [
            "forget", "--prune",
            "--keep-last", "3",
            "--keep-daily", "7",
            "--keep-weekly", "5",
            "--keep-monthly", "12",
        ])
        XCTAssertEqual(ResticCommand.forget(retention: .month).arguments, [
            "forget", "--prune",
            "--keep-last", "3",
            "--keep-daily", "7",
            "--keep-weekly", "4",
        ])
        // Never issued by the app — PrunePolicy.isDue is false for .off —
        // and restic rejects the bare command rather than deleting anything.
        XCTAssertEqual(ResticCommand.forget(retention: .off).arguments, ["forget", "--prune"])
    }

    func testRestoreArguments() {
        let command = ResticCommand.restore(snapshotID: "c4e6a708", target: "/tmp/restored")
        XCTAssertEqual(command.arguments, ["restore", "c4e6a708", "--target", "/tmp/restored", "--json"])
    }

    func testLocalRepositoryLocation() {
        let destination = Destination.local(path: "/Volumes/Backup/keelhaven")
        XCTAssertEqual(destination.repositoryLocation, "/Volumes/Backup/keelhaven")
    }

    func testS3RepositoryLocationAddsSchemeAndTrimsPrefix() {
        let bare = Destination.s3(S3Config(
            endpoint: "s3.eu-central-1.amazonaws.com",
            bucket: "my-backups",
            pathPrefix: "/mac/",
            accessKeyID: "AKIAEXAMPLE"
        ))
        XCTAssertEqual(
            bare.repositoryLocation,
            "s3:https://s3.eu-central-1.amazonaws.com/my-backups/mac"
        )

        let withScheme = Destination.s3(S3Config(
            endpoint: "http://minio.local:9000",
            bucket: "backups",
            pathPrefix: "",
            accessKeyID: "minio"
        ))
        XCTAssertEqual(withScheme.repositoryLocation, "s3:http://minio.local:9000/backups")
    }

    func testSFTPRepositoryLocation() {
        let standardPort = Destination.sftp(SFTPConfig(user: "sxp", host: "nas.local", port: 22, path: "/backups/mac"))
        XCTAssertEqual(standardPort.repositoryLocation, "sftp:sxp@nas.local:/backups/mac")

        let customPort = Destination.sftp(SFTPConfig(user: "sxp", host: "nas.local", port: 2222, path: "/backups/mac"))
        XCTAssertEqual(customPort.repositoryLocation, "sftp://sxp@nas.local:2222//backups/mac")
    }

    func testEnvironmentContainsSecretsAndCleanBase() {
        let destination = Destination.s3(S3Config(
            endpoint: "s3.amazonaws.com",
            bucket: "bucket",
            pathPrefix: "",
            accessKeyID: "AKIAEXAMPLE"
        ))
        let credentials = RepoCredentials(repositoryPassword: "hunter22", s3SecretAccessKey: "sekrit")
        let env = credentials.environment(for: destination)

        XCTAssertEqual(env["RESTIC_PASSWORD"], "hunter22")
        XCTAssertEqual(env["RESTIC_REPOSITORY"], "s3:https://s3.amazonaws.com/bucket")
        XCTAssertEqual(env["AWS_ACCESS_KEY_ID"], "AKIAEXAMPLE")
        XCTAssertEqual(env["AWS_SECRET_ACCESS_KEY"], "sekrit")
        XCTAssertNotNil(env["PATH"], "restic needs PATH to find ssh for sftp")

        // The app's own environment must not leak wholesale into the child.
        let allowedKeys: Set<String> = [
            "PATH", "HOME", "TMPDIR", "SSH_AUTH_SOCK",
            "RESTIC_REPOSITORY", "RESTIC_PASSWORD",
            "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
        ]
        XCTAssertTrue(Set(env.keys).isSubset(of: allowedKeys), "Unexpected keys: \(Set(env.keys).subtracting(allowedKeys))")
    }

    func testLocalDestinationOmitsAWSVariables() {
        let credentials = RepoCredentials(repositoryPassword: "pw")
        let env = credentials.environment(for: .local(path: "/tmp/repo"))
        XCTAssertNil(env["AWS_ACCESS_KEY_ID"])
        XCTAssertNil(env["AWS_SECRET_ACCESS_KEY"])
    }
}
