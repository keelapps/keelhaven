import Foundation
import Observation
import KeelhavenCore

enum DestinationType: String, CaseIterable, Identifiable {
    case local = "Local / External Drive"
    case s3 = "S3-Compatible"
    case sftp = "SFTP / NAS"

    var id: String { rawValue }
}

enum ScheduleKind: String, CaseIterable, Identifiable {
    case hourly = "Every hour"
    case daily = "Once a day"

    var id: String { rawValue }
}

/// Draft state for the 3-step wizard, with per-step validation.
@MainActor
@Observable
final class WizardModel {
    static let stepCount = 3

    var step = 0
    var name = ""
    var sourcePaths: [String] = []

    var destinationType: DestinationType = .local
    var localPath = ""
    var s3Endpoint = ""
    var s3Bucket = ""
    var s3Prefix = ""
    var s3AccessKey = ""
    var s3SecretKey = ""
    var sftpUser = ""
    var sftpHost = ""
    var sftpPort = "22"
    var sftpPath = ""
    var password = ""
    var passwordConfirm = ""
    var passwordWasGenerated = false

    var scheduleKind: ScheduleKind = .daily
    var dailyTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()

    var isCreating = false
    var creationError: String?

    /// Repository locations of already-configured plans, injected by the
    /// wizard window. Two plans must never share one repository: the second
    /// init would fail, and the passwords could diverge (issues #4/#5).
    var existingRepositoryLocations: [String] = []

    // MARK: - Validation

    var sourcesStepValid: Bool {
        !sourcePaths.isEmpty
    }

    var destinationStepValid: Bool {
        destinationFieldsValid && passwordValid
    }

    var passwordValid: Bool {
        password.count >= 8 && password == passwordConfirm
    }

    var destinationFieldsValid: Bool {
        switch destinationType {
        case .local:
            return !localPath.isEmpty && !localDestinationInsideSource && !destinationAlreadyUsed
        case .s3:
            return !s3Endpoint.isEmpty && !s3Bucket.isEmpty && !s3AccessKey.isEmpty && !s3SecretKey.isEmpty
                && !destinationAlreadyUsed
        case .sftp:
            return !sftpUser.isEmpty && !sftpHost.isEmpty && !sftpPath.isEmpty && Int(sftpPort) != nil
                && !destinationAlreadyUsed
        }
    }

    /// True when the draft destination matches an existing plan's repository.
    var destinationAlreadyUsed: Bool {
        existingRepositoryLocations.contains(currentDestination.repositoryLocation)
    }

    private var currentDestination: Destination {
        switch destinationType {
        case .local:
            return .local(path: localPath)
        case .s3:
            return .s3(S3Config(
                endpoint: s3Endpoint,
                bucket: s3Bucket,
                pathPrefix: s3Prefix,
                accessKeyID: s3AccessKey
            ))
        case .sftp:
            return .sftp(SFTPConfig(
                user: sftpUser,
                host: sftpHost,
                port: Int(sftpPort) ?? 22,
                path: sftpPath
            ))
        }
    }

    /// Backing up a folder into itself would recursively back up the repository.
    var localDestinationInsideSource: Bool {
        guard destinationType == .local, !localPath.isEmpty else { return false }
        let destination = localPath.hasSuffix("/") ? localPath : localPath + "/"
        return sourcePaths.contains { source in
            let prefix = source.hasSuffix("/") ? source : source + "/"
            return destination.hasPrefix(prefix)
        }
    }

    var canAdvance: Bool {
        switch step {
        case 0: return sourcesStepValid
        case 1: return destinationStepValid
        default: return true
        }
    }

    /// Fills both password fields with a generated passphrase. Ambiguous
    /// characters (0/O, 1/l/I) are excluded since users may need to type it
    /// during a future restore.
    func generatePassword() {
        let charset = Array("abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        password = String((0..<20).compactMap { _ in charset.randomElement() })
        passwordConfirm = password
        passwordWasGenerated = true
    }

    // MARK: - Draft assembly

    var defaultName: String {
        if let first = sourcePaths.first {
            return URL(fileURLWithPath: first).lastPathComponent
        }
        return "My Backup"
    }

    /// The name this model last wrote into `name` itself. Lets
    /// `syncAutofilledName` distinguish its own writes from user input.
    private var lastAutofilledName: String?

    /// Keeps the name field showing the first folder's name as real,
    /// editable text instead of a grayed-out placeholder — so users can see
    /// the field is theirs to change. Never overwrites a name the user typed.
    func syncAutofilledName() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty || trimmed == lastAutofilledName else { return }
        if let first = sourcePaths.first {
            name = URL(fileURLWithPath: first).lastPathComponent
            lastAutofilledName = name
        } else {
            name = ""
            lastAutofilledName = nil
        }
    }

    func buildDraft() -> PlanDraft {
        let destination = currentDestination

        let schedule: Schedule
        switch scheduleKind {
        case .hourly:
            schedule = .hourly
        case .daily:
            let components = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
            schedule = .daily(hour: components.hour ?? 21, minute: components.minute ?? 0)
        }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        return PlanDraft(
            name: trimmedName.isEmpty ? defaultName : trimmedName,
            sourcePaths: sourcePaths,
            destination: destination,
            schedule: schedule,
            password: password,
            s3SecretKey: destinationType == .s3 ? s3SecretKey : nil
        )
    }

    func reset() {
        let fresh = WizardModel()
        step = fresh.step
        name = fresh.name
        sourcePaths = fresh.sourcePaths
        destinationType = fresh.destinationType
        localPath = fresh.localPath
        s3Endpoint = fresh.s3Endpoint
        s3Bucket = fresh.s3Bucket
        s3Prefix = fresh.s3Prefix
        s3AccessKey = fresh.s3AccessKey
        s3SecretKey = fresh.s3SecretKey
        sftpUser = fresh.sftpUser
        sftpHost = fresh.sftpHost
        sftpPort = fresh.sftpPort
        sftpPath = fresh.sftpPath
        password = fresh.password
        passwordConfirm = fresh.passwordConfirm
        passwordWasGenerated = fresh.passwordWasGenerated
        scheduleKind = fresh.scheduleKind
        dailyTime = fresh.dailyTime
        isCreating = fresh.isCreating
        creationError = fresh.creationError
        lastAutofilledName = fresh.lastAutofilledName
    }
}
