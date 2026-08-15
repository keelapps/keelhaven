import Foundation

/// A mounted external drive suitable for holding backups.
struct ExternalDrive: Identifiable, Equatable {
    let id: String
    let name: String
    let url: URL
    let freeBytes: Int64?
    let isWritable: Bool
}

/// Finds plugged-in external drives so the wizard can offer them as
/// one-click backup destinations — no path typing.
enum ExternalDriveService {
    static func detect() -> [ExternalDrive] {
        let keys: [URLResourceKey] = [
            .volumeIsInternalKey,
            .volumeIsLocalKey,
            .volumeIsBrowsableKey,
            .volumeIsReadOnlyKey,
            .volumeNameKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ]
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []

        var drives: [ExternalDrive] = []
        for url in volumes {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            // External: not the built-in disk. Local: excludes network shares
            // (those are the advanced SFTP path). Browsable: user-visible.
            guard values.volumeIsInternal == false,
                  values.volumeIsLocal == true,
                  values.volumeIsBrowsable == true
            else { continue }

            // Best-effort: skip drives that look like Time Machine targets.
            let timeMachineMarker = url.appendingPathComponent("Backups.backupdb").path
            if FileManager.default.fileExists(atPath: timeMachineMarker) { continue }

            let readOnly = values.volumeIsReadOnly ?? false
            drives.append(ExternalDrive(
                id: url.path,
                name: values.volumeName ?? url.lastPathComponent,
                url: url,
                freeBytes: values.volumeAvailableCapacityForImportantUsage,
                isWritable: !readOnly && FileManager.default.isWritableFile(atPath: url.path)
            ))
        }
        return drives.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// The folder Keelhaven proposes on a chosen drive. Deliberately never
    /// localized: the on-disk path must stay stable across language switches.
    static func proposedBackupPath(on drive: ExternalDrive) -> String {
        drive.url.appendingPathComponent("Keelhaven Backups").path
    }
}
