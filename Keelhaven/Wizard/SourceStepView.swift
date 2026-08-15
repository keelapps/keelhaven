import SwiftUI

/// A common folder offered as a one-click chip on the source step.
private struct PresetFolder: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let url: URL?

    static let all: [PresetFolder] = [
        PresetFolder(
            id: "documents",
            title: String(localized: "Documents"),
            symbol: "doc",
            url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        ),
        PresetFolder(
            id: "desktop",
            title: String(localized: "Desktop"),
            symbol: "desktopcomputer",
            url: FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        ),
        PresetFolder(
            id: "pictures",
            title: String(localized: "Pictures"),
            symbol: "photo",
            url: FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
        ),
    ]
}

struct SourceStepView: View {
    @Bindable var model: WizardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose the folders to back up.")
                .font(.title3)

            presetChips

            TextField("Plan name (optional)", text: $model.name, prompt: Text(model.defaultName))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 300)

            List {
                ForEach(model.sourcePaths, id: \.self) { path in
                    HStack {
                        Image(systemName: "folder")
                        Text(path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button {
                            model.sourcePaths.removeAll { $0 == path }
                            model.syncAutofilledName()
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(path)")
                    }
                }
            }
            .frame(minHeight: 160)
            .overlay {
                if model.sourcePaths.isEmpty {
                    Text("No folders yet — add at least one.")
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                let urls = FolderPicker.pickFolders()
                for url in urls where !model.sourcePaths.contains(url.path) {
                    model.sourcePaths.append(url.path)
                }
                model.syncAutofilledName()
            } label: {
                Label("Add Folders…", systemImage: "plus")
            }
        }
    }

    /// One-click toggles for the folders most people want backed up.
    private var presetChips: some View {
        HStack(spacing: 8) {
            ForEach(PresetFolder.all) { preset in
                if let url = preset.url {
                    let selected = model.sourcePaths.contains(url.path)
                    Button {
                        if selected {
                            model.sourcePaths.removeAll { $0 == url.path }
                        } else {
                            model.sourcePaths.append(url.path)
                        }
                        model.syncAutofilledName()
                    } label: {
                        Label(preset.title, systemImage: selected ? "checkmark.circle.fill" : preset.symbol)
                    }
                    .buttonStyle(.bordered)
                    .tint(selected ? Color.accentColor : nil)
                    .accessibilityLabel(
                        selected
                            ? String(localized: "\(preset.title), selected for backup")
                            : String(localized: "Back up \(preset.title)")
                    )
                }
            }
        }
    }
}
