import SwiftUI

/// Small About window: version, build number, and the git commit embedded at
/// build time — enough to match an installed app to a CI run when debugging.
///
/// Also carries the notice for the restic binary bundled in Contents/MacOS:
/// we redistribute it, so BSD-2-Clause clause 2 obliges us to reproduce its
/// copyright notice and disclaimer with the distribution.
struct AboutView: View {
    @State private var showingLicense = false

    /// restic's licence text, copied into Contents/Resources by the
    /// `Vendor/restic/restic-LICENSE.txt` copy phase declared in project.yml
    /// and fetched from the pinned tag by Scripts/fetch-restic.sh.
    private var resticLicense: String? {
        guard let url = Bundle.main.url(forResource: "restic-LICENSE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return text
    }

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

            Divider()
                .padding(.top, 4)

            acknowledgements
        }
        .padding(28)
        .frame(width: 320)
    }

    /// The attribution line stays visible unconditionally — collapsing it
    /// behind the disclosure would leave the notice technically shipped but
    /// practically hidden. Only the full text is opt-in.
    private var acknowledgements: some View {
        VStack(spacing: 6) {
            Text("Backups are made by restic, © 2014 Alexander Neumann, used under the BSD 2-Clause License.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            DisclosureGroup(isExpanded: $showingLicense) {
                ScrollView {
                    // Never localized: this is the licence text verbatim.
                    Text(resticLicense ?? "License text unavailable.")
                        .font(.caption2.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 150)
            } label: {
                Text("Full license text")
                    .font(.caption)
            }
        }
    }
}
