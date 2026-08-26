import Foundation
import KeelhavenCore

/// Checks the public `latest.json` manifest mirrored to keelhaven.app
/// alongside every release DMG. Never surfaces a network or parsing
/// failure to the user — a bad manifest or offline machine just means no
/// update prompt this launch, not an error.
enum UpdateChecker {
    private static let manifestURL = URL(string: "https://keelhaven.app/latest.json")!

    static func checkForUpdate() async -> UpdateInfo? {
        guard let (data, _) = try? await URLSession.shared.data(from: manifestURL),
              let info = try? JSONDecoder().decode(UpdateInfo.self, from: data)
        else {
            return nil
        }
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        guard SemanticVersion.isNewer(info.version, than: currentVersion) else {
            return nil
        }
        return info
    }
}
