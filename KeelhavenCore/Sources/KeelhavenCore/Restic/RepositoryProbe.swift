import Foundation

/// Cheap local checks about restic repositories, shared by the wizard (live
/// validation while the user picks a destination) and plan creation.
public enum RepositoryProbe {
    /// True when the folder already contains a restic repository — its
    /// `config` file exists. A plain stat, safe to call from UI validation.
    public static func localPathContainsRepository(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        let configPath = (path as NSString).appendingPathComponent("config")
        return FileManager.default.fileExists(atPath: configPath)
    }
}
