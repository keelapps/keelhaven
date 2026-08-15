import SwiftUI
import KeelhavenCore

// The UI-side vocabulary for Schedule, shared by the wizard's schedule step,
// the plan row's caption, and the Edit Plan window — one mapping, one wording.

extension Schedule {
    /// The default time-of-day offered when a plan switches to daily: 21:00,
    /// same as the wizard's initial value.
    static var defaultDailyTime: Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }

    init(kind: ScheduleKind, dailyTime: Date) {
        switch kind {
        case .hourly:
            self = .hourly
        case .daily:
            let components = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
            self = .daily(hour: components.hour ?? 21, minute: components.minute ?? 0)
        }
    }

    /// The inverse of `init(kind:dailyTime:)`, for seeding edit controls from
    /// a stored plan. An hourly plan still carries a sensible daily time so
    /// switching the picker to daily doesn't land on a random hour.
    var editorComponents: (kind: ScheduleKind, dailyTime: Date) {
        switch self {
        case .hourly:
            return (.hourly, Self.defaultDailyTime)
        case .daily(let hour, let minute):
            let time = Calendar.current.date(
                bySettingHour: hour, minute: minute, second: 0, of: Date()
            ) ?? Self.defaultDailyTime
            return (.daily, time)
        }
    }

    /// "Every hour" / "Daily at 21:00", following the user's locale and
    /// 12/24-hour preference.
    var displayText: String {
        switch self {
        case .hourly:
            return String(localized: "Every hour")
        case .daily:
            let time = editorComponents.dailyTime.formatted(date: .omitted, time: .shortened)
            return String(localized: "Daily at \(time)")
        }
    }
}

/// The frequency picker + conditional time-of-day picker, extracted from the
/// wizard's schedule step so the Edit Plan window shows the identical controls.
struct ScheduleEditor: View {
    @Binding var kind: ScheduleKind
    @Binding var dailyTime: Date

    var body: some View {
        Picker("Frequency", selection: $kind) {
            ForEach(ScheduleKind.allCases) { kind in
                Text(kind.localizedTitle).tag(kind)
            }
        }
        .pickerStyle(.radioGroup)
        .labelsHidden()

        if kind == .daily {
            DatePicker(
                "At",
                selection: $dailyTime,
                displayedComponents: .hourAndMinute
            )
            .frame(maxWidth: 200)
        }
    }
}
