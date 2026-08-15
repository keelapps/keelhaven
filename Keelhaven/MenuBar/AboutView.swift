import SwiftUI

/// Small About window: version, build number, and the git commit embedded at
/// build time — enough to match an installed app to a CI run when debugging.
struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    private var commit: String {
        Bundle.main.object(forInfoDictionaryKey: "GitCommit") as? String ?? "unknown"
    }

    private var versionLine: String {
        String(localized: "Version \(version) (build \(build), \(commit))")
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)

            Text("Keelhaven")
                .font(.title2.bold())

            Text(versionLine)
                .font(.callout.monospaced())
                .textSelection(.enabled)

            Text("Privacy-first backup to your own storage.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button("Copy Version Info") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("Keelhaven \(versionLine)", forType: .string)
            }
            .font(.callout)
        }
        .padding(28)
        .frame(width: 320)
    }
}
