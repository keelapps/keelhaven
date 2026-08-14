import Foundation

/// Executes restic as a child process.
///
/// One-shot commands (`init`, `snapshots`, `stats`) collect stdout and decode
/// it in one go via `run(_:destination:credentials:decoding:)`. Backups stream
/// their JSON-lines progress through `backupStream(...)`.
public actor ResticRunner {
    public let binaryURL: URL

    public init(binaryURL: URL) {
        self.binaryURL = binaryURL
    }

    // MARK: - One-shot commands

    public func run<Output: Decodable>(
        _ command: ResticCommand,
        destination: Destination,
        credentials: RepoCredentials,
        decoding type: Output.Type
    ) async throws -> Output {
        let result = try await execute(command, destination: destination, credentials: credentials)
        guard result.exitCode == 0 else {
            throw ResticError.classify(exitCode: result.exitCode, stderr: result.stderrText)
        }
        do {
            return try ResticJSON.decoder.decode(Output.self, from: result.stdout)
        } catch {
            throw ResticError.outputDecodingFailed(message: String(describing: error))
        }
    }

    /// Like `run`, for commands whose output we don't need (e.g. `check`).
    public func runIgnoringOutput(
        _ command: ResticCommand,
        destination: Destination,
        credentials: RepoCredentials
    ) async throws {
        let result = try await execute(command, destination: destination, credentials: credentials)
        guard result.exitCode == 0 else {
            throw ResticError.classify(exitCode: result.exitCode, stderr: result.stderrText)
        }
    }

    // MARK: - Streaming backup

    /// Runs `restic backup` and yields decoded progress events as they arrive.
    /// The stream finishes after the summary event on success, or throws a
    /// `ResticError` on failure. Cancelling the consuming task sends SIGINT to
    /// restic, which exits and unlocks the repository cleanly.
    public nonisolated func backupStream(
        _ command: ResticCommand,
        destination: Destination,
        credentials: RepoCredentials
    ) -> AsyncThrowingStream<BackupProgressEvent, Error> {
        let binaryURL = self.binaryURL
        return AsyncThrowingStream { continuation in
            let process = Process()
            process.executableURL = binaryURL
            process.arguments = command.arguments
            process.environment = credentials.environment(for: destination)
            process.standardInput = FileHandle.nullDevice

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            // Install the termination bridge before launching so an early exit
            // can never be missed.
            let exitCodes = AsyncStream<Int32> { exitContinuation in
                process.terminationHandler = { finished in
                    exitContinuation.yield(finished.terminationStatus)
                    exitContinuation.finish()
                }
            }

            let worker = Task {
                do {
                    try process.run()
                } catch {
                    continuation.finish(throwing: ResticError.binaryNotFound)
                    return
                }

                async let stderrData = ResticRunner.collect(stderrPipe.fileHandleForReading)

                do {
                    for try await line in stdoutPipe.fileHandleForReading.bytes.lines {
                        if let event = ResticJSON.decodeProgressEvent(fromLine: line) {
                            continuation.yield(event)
                        }
                    }
                } catch {
                    // stdout read failure: fall through, the exit code decides
                }

                var exitCode: Int32 = -1
                for await code in exitCodes {
                    exitCode = code
                }

                if exitCode == 0 {
                    continuation.finish()
                } else {
                    let stderrText = String(decoding: await stderrData, as: UTF8.self)
                    continuation.finish(throwing: ResticError.classify(exitCode: exitCode, stderr: stderrText))
                }
            }

            continuation.onTermination = { termination in
                guard case .cancelled = termination else { return }
                if process.isRunning {
                    process.interrupt() // SIGINT: restic unlocks and exits
                }
                worker.cancel()
            }
        }
    }

    // MARK: - Process plumbing

    private struct ExecutionResult {
        let exitCode: Int32
        let stdout: Data
        let stderr: Data

        var stderrText: String {
            String(decoding: stderr, as: UTF8.self)
        }
    }

    private func execute(
        _ command: ResticCommand,
        destination: Destination,
        credentials: RepoCredentials
    ) async throws -> ExecutionResult {
        let process = Process()
        process.executableURL = binaryURL
        process.arguments = command.arguments
        process.environment = credentials.environment(for: destination)
        process.standardInput = FileHandle.nullDevice

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let exitCodes = AsyncStream<Int32> { exitContinuation in
            process.terminationHandler = { finished in
                exitContinuation.yield(finished.terminationStatus)
                exitContinuation.finish()
            }
        }

        do {
            try process.run()
        } catch {
            throw ResticError.binaryNotFound
        }

        // Read both pipes concurrently with the running process so a large
        // output can never fill the pipe buffer and deadlock the child.
        async let stdoutData = ResticRunner.collect(stdoutPipe.fileHandleForReading)
        async let stderrData = ResticRunner.collect(stderrPipe.fileHandleForReading)

        var exitCode: Int32 = -1
        for await code in exitCodes {
            exitCode = code
        }

        return ExecutionResult(exitCode: exitCode, stdout: await stdoutData, stderr: await stderrData)
    }

    private static func collect(_ handle: FileHandle) async -> Data {
        var data = Data()
        do {
            for try await byte in handle.bytes {
                data.append(byte)
            }
        } catch {
            // Partial output is still useful for error reporting.
        }
        return data
    }
}
