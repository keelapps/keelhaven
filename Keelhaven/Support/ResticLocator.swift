import Foundation
import KeelhavenCore

/// Finds the restic binary. v1 uses the user's own install (Homebrew paths or
/// a manual override in UserDefaults); a bundled binary is the ship-phase plan.
enum ResticLocator {
    static let overrideDefaultsKey = "resticBinaryPath"
    static let minimumVersionText = "0.19"
    private static let minimumVersion = (major: 0, minor: 19)

    static let knownPaths = [
        "/opt/homebrew/bin/restic",
        "/usr/local/bin/restic",
    ]

    static func locate() -> URL? {
        if let override = UserDefaults.standard.string(forKey: overrideDefaultsKey),
           FileManager.default.isExecutableFile(atPath: override) {
            return URL(fileURLWithPath: override)
        }
        for path in knownPaths where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    /// Runs `restic version` and checks the reported version against the minimum.
    /// Returns true when the version cannot be parsed, to avoid blocking on
    /// unexpected but probably-fine output.
    static func meetsMinimumVersion(at binaryURL: URL) async -> Bool {
        guard let output = await versionOutput(at: binaryURL) else {
            return false
        }
        guard let version = parseVersion(from: output) else {
            return true
        }
        if version.major != minimumVersion.major {
            return version.major > minimumVersion.major
        }
        return version.minor >= minimumVersion.minor
    }

    /// Parses "restic 0.19.1 compiled with …" into (0, 19).
    static func parseVersion(from output: String) -> (major: Int, minor: Int)? {
        let words = output.split(separator: " ")
        guard words.count >= 2, words[0] == "restic" else { return nil }
        let numbers = words[1].split(separator: ".")
        guard numbers.count >= 2,
              let major = Int(numbers[0]),
              let minor = Int(numbers[1])
        else { return nil }
        return (major, minor)
    }

    private static func versionOutput(at binaryURL: URL) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = binaryURL
                process.arguments = ["version"]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                process.standardInput = FileHandle.nullDevice
                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: nil)
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: String(decoding: data, as: UTF8.self))
            }
        }
    }
}
