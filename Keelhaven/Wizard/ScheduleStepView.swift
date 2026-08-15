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
                    Text(kind.localizedTitle).tag(kind)
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
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            summary
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Summary")
                .font(.headline)
            summaryRow(label: String(localized: "Name"), value: model.name.isEmpty ? model.defaultName : model.name)
            summaryRow(
                label: String(localized: "Folders"),
                value: model.sourcePaths.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
            )
            summaryRow(label: String(localized: "Destination"), value: model.buildDraft().destination.displayName)
            summaryRow(label: String(localized: "Schedule"), value: scheduleText)
        }
    }

    private var scheduleText: String {
        switch model.scheduleKind {
        case .hourly:
            return String(localized: "Every hour")
        case .daily:
            return String(localized: "Daily at \(model.dailyTime.formatted(date: .omitted, time: .shortened))")
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
