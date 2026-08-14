import SwiftUI
import KeelhavenCore

struct WizardWindowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var model = WizardModel()

    private let stepTitles = ["What to back up", "Where to", "When"]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Group {
                switch model.step {
                case 0:
                    SourceStepView(model: model)
                case 1:
                    DestinationStepView(model: model)
                default:
                    ScheduleStepView(model: model)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()
            footer
        }
        .frame(width: 560, height: 500)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ForEach(0..<WizardModel.stepCount, id: \.self) { index in
                HStack(spacing: 6) {
                    Image(systemName: index < model.step ? "checkmark.circle.fill" : "\(index + 1).circle")
                        .foregroundStyle(index <= model.step ? Color.accentColor : Color.secondary)
                    Text(stepTitles[index])
                        .fontWeight(index == model.step ? .semibold : .regular)
                        .foregroundStyle(index == model.step ? .primary : .secondary)
                }
                if index < WizardModel.stepCount - 1 {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: 40)
                }
            }
        }
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(model.step + 1) of \(WizardModel.stepCount): \(stepTitles[model.step])")
    }

    private var footer: some View {
        HStack {
            if let creationError = model.creationError {
                Text(creationError)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
            Spacer()

            if model.step > 0 {
                Button("Back") {
                    model.step -= 1
                }
                .disabled(model.isCreating)
            }

            if model.step < WizardModel.stepCount - 1 {
                Button("Next") {
                    model.step += 1
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canAdvance)
            } else {
                Button {
                    create()
                } label: {
                    if model.isCreating {
                        Text("Creating Repository…")
                    } else {
                        Text("Create Backup Plan")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(model.isCreating)
            }
        }
        .padding(16)
    }

    private func create() {
        model.isCreating = true
        model.creationError = nil
        let draft = model.buildDraft()
        Task {
            do {
                try await appState.createPlan(from: draft)
                model.isCreating = false
                model.reset()
                dismiss()
            } catch {
                model.isCreating = false
                model.creationError = error.localizedDescription
            }
        }
    }
}
