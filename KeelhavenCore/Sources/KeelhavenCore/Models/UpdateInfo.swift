import Foundation

/// The shape of the public `latest.json` manifest mirrored to keelhaven.app
/// alongside every signed release DMG.
public struct UpdateInfo: Codable, Hashable, Sendable {
    public let version: String
    public let dmgURL: URL

    public init(version: String, dmgURL: URL) {
        self.version = version
        self.dmgURL = dmgURL
    }
}

/// Dotted-integer version comparison (e.g. "1.10.0" vs "1.9.9"). Missing
/// trailing components are treated as zero, so "1.2" equals "1.2.0".
public enum SemanticVersion {
    /// Conservative on malformed input: an unparsable version never counts
    /// as newer, so a bad manifest can't false-positive a nag to update.
    public static func isNewer(_ remote: String, than local: String) -> Bool {
        guard let remoteParts = components(remote), let localParts = components(local) else {
            return false
        }
        let length = max(remoteParts.count, localParts.count)
        for index in 0..<length {
            let remoteValue = index < remoteParts.count ? remoteParts[index] : 0
            let localValue = index < localParts.count ? localParts[index] : 0
            if remoteValue != localValue {
                return remoteValue > localValue
            }
        }
        return false
    }

    private static func components(_ version: String) -> [Int]? {
        let parts = version.split(separator: ".", omittingEmptySubsequences: false)
        var numbers: [Int] = []
        numbers.reserveCapacity(parts.count)
        for part in parts {
            guard let number = Int(part) else { return nil }
            numbers.append(number)
        }
        return numbers
    }
}
