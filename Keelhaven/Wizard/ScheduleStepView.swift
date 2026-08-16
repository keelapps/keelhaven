import SwiftUI
import KeelhavenCore

struct ScheduleStepView: View {
    @Bindable var model: WizardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How often should it run?")
                .font(.title3)

            ScheduleEditor(kind: $model.scheduleKind, dailyTime: $model.dailyTime, weekday: $model.weekday)

            // Surprise-proofing, not decoration: the first run starts on
            // creation (SchedulePolicy treats a never-run plan as due), and
            // users who set an evening time expect silence until then. One
            // footnote-sized block, System Settings style — not two callout
            // paragraphs competing with the summary.
            Text("The first backup starts as soon as you create the plan. After that, backups run on this schedule, catching up automatically if your Mac was asleep or off.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            summary
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Summary")
                .font(.headline)
            // The name is editable here, not on the source step: step one is
            // purely about picking folders, and the autofilled default (first
            // folder's name) only settles once those are chosen.
            HStack(alignment: .firstTextBaseline) {
                Text("Name")
                    .foregroundStyle(.secondary)
                    .frame(width: 90, alignment: .leading)
                TextField("Plan name (optional)", text: $model.name, prompt: Text(model.defaultName))
                    .textFieldStyle(.roundedBorder)
                    .labelsHidden()
                    .frame(maxWidth: 300)
            }
            .font(.callout)
            summaryRow(
                label: String(localized: "Folders"),
                value: model.sourcePaths.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
            )
            summaryRow(label: String(localized: "Destination"), value: model.buildDraft().destination.displayName)
            summaryRow(
                label: String(localized: "Schedule"),
                value: Schedule(kind: model.scheduleKind, dailyTime: model.dailyTime, weekday: model.weekday).displayText
            )
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
