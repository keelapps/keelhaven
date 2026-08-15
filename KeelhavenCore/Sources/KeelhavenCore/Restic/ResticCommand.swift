import Foundation

/// A restic subcommand plus its arguments. The repository location and all
/// secrets travel via environment variables, never argv (argv is visible to
/// every process on the machine).
public enum ResticCommand: Equatable, Sendable {
    case initRepository
    case backup(sources: [String], excludes: [String], tag: String?)
    case snapshots
    case stats
    case check
    /// Reads the repository config — the cheapest command that proves a
    /// password opens an existing repository (used when adopting one).
    case catConfig

    public var arguments: [String] {
        switch self {
        case .initRepository:
            return ["init", "--json"]
        case .backup(let sources, let excludes, let tag):
            var args = ["backup", "--json"]
            for pattern in excludes {
                args.append("--exclude")
                args.append(pattern)
            }
            if let tag, !tag.isEmpty {
                args.append("--tag")
                args.append(tag)
            }
            args.append(contentsOf: sources)
            return args
        case .snapshots:
            return ["snapshots", "--json"]
        case .stats:
            return ["stats", "--json"]
        case .check:
            return ["check"]
        case .catConfig:
            return ["cat", "config", "--json"]
        }
    }
}
