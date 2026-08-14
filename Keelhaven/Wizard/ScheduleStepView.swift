import SwiftUI
import KeelhavenCore

struct ScheduleStepView: View {
    @Bindable var model: WizardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How often should it run?")
                .font(.title3)

            Picker("Frequency", selection: $model.scheduleKind) {
                ForEach(ScheduleKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            if model.scheduleKind == .daily {
                DatePicker(
                    "At",
                    selection: $model.dailyTime,
                    displayedComponents: .hourAndMinute
                )
                .frame(maxWidth: 200)
            }

            Text("Keelhaven also catches up automatically after your Mac was asleep or off at the scheduled time.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            summary
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Summary")
                .font(.headline)
            summaryRow(label: "Name", value: model.name.isEmpty ? model.defaultName : model.name)
            summaryRow(
                label: "Folders",
                value: model.sourcePaths.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
            )
            summaryRow(label: "Destination", value: model.buildDraft().destination.displayName)
            summaryRow(label: "Schedule", value: scheduleText)
        }
    }

    private var scheduleText: String {
        switch model.scheduleKind {
        case .hourly:
            return "Every hour"
        case .daily:
            return "Daily at \(model.dailyTime.formatted(date: .omitted, time: .shortened))"
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .font(.callout)
    }
}
