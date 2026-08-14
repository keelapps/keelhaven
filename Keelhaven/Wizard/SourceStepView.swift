import SwiftUI

struct SourceStepView: View {
    @Bindable var model: WizardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose the folders to back up.")
                .font(.title3)

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
}
