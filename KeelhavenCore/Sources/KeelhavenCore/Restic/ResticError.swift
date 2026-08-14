import Foundation

/// Typed failures from the restic layer.
///
/// Exit codes verified against restic 0.19.1 (see Tests/…/Fixtures):
///   10 = repository does not exist, 12 = wrong password.
///   11 (lock) is documented by restic but not reproduced in fixtures.
public enum ResticError: Error, Equatable, Sendable {
    case binaryNotFound
    case repositoryDoesNotExist(message: String)
    case repositoryLocked(message: String)
    case wrongPassword(message: String)
    case commandFailed(exitCode: Int, message: String)
    case outputDecodingFailed(message: String)

    public static func classify(exitCode: Int32, stderr: String) -> ResticError {
        // restic ≥0.17 writes a {"message_type":"exit_error","code":…,"message":…}
        // JSON line to stderr; prefer its message over raw stderr.
        var message = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        for line in stderr.split(separator: "\n").reversed() {
            if let data = line.data(using: .utf8),
               let exitError = try? ResticJSON.decoder.decode(ResticExitError.self, from: data) {
                message = exitError.message
                break
            }
        }

        switch exitCode {
        case 10:
            return .repositoryDoesNotExist(message: message)
        case 11:
            return .repositoryLocked(message: message)
        case 12:
            return .wrongPassword(message: message)
        default:
            return .commandFailed(exitCode: Int(exitCode), message: message)
        }
    }
}

extension ResticError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "The restic command-line tool could not be found. Install it with: brew install restic"
        case .repositoryDoesNotExist(let message):
            return "The backup repository was not found. \(message)"
        case .repositoryLocked(let message):
            return "The backup repository is locked by another process. \(message)"
        case .wrongPassword(let message):
            return "The repository password is incorrect. \(message)"
        case .commandFailed(let exitCode, let message):
            return "Backup command failed (exit code \(exitCode)). \(message)"
        case .outputDecodingFailed(let message):
            return "Could not understand restic's output. \(message)"
        }
    }
}
