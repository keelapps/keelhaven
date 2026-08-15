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

    init(kind: ScheduleKind, dailyTime: Date, weekday: Int) {
        switch kind {
        case .hourly:
            self = .hourly
        case .daily:
            let components = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
            self = .daily(hour: components.hour ?? 21, minute: components.minute ?? 0)
        case .weekly:
            let components = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
            self = .weekly(
                weekday: weekday,
                hour: components.hour ?? 21,
                minute: components.minute ?? 0
            )
        }
    }

    /// The inverse of `init(kind:dailyTime:weekday:)`, for seeding edit
    /// controls from a stored plan. Every case carries a sensible time and
    /// weekday so switching the picker doesn't land on a random value.
    var editorComponents: (kind: ScheduleKind, dailyTime: Date, weekday: Int) {
        switch self {
        case .hourly:
            return (.hourly, Self.defaultDailyTime, Calendar.current.firstWeekday)
        case .daily(let hour, let minute):
            let time = Calendar.current.date(
                bySettingHour: hour, minute: minute, second: 0, of: Date()
            ) ?? Self.defaultDailyTime
            return (.daily, time, Calendar.current.firstWeekday)
        case .weekly(let weekday, let hour, let minute):
            let time = Calendar.current.date(
                bySettingHour: hour, minute: minute, second: 0, of: Date()
            ) ?? Self.defaultDailyTime
            return (.weekly, time, weekday)
        }
    }

    /// "Every hour" / "Daily at 21:00" / "Weekly on Sunday at 21:00",
    /// following the user's locale and 12/24-hour preference.
    var displayText: String {
        switch self {
        case .hourly:
            return String(localized: "Every hour")
        case .daily:
            let time = editorComponents.dailyTime.formatted(date: .omitted, time: .shortened)
            return String(localized: "Daily at \(time)")
        case .weekly(let weekday, _, _):
            let time = editorComponents.dailyTime.formatted(date: .omitted, time: .shortened)
            let day = Self.weekdayName(weekday)
            return String(localized: "Weekly on \(day) at \(time)")
        }
    }

    /// Localized weekday name for a Calendar weekday number (1 = Sunday).
    static func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        guard (1...symbols.count).contains(weekday) else { return "?" }
        return symbols[weekday - 1]
    }
}

/// The frequency picker + conditional time-of-day picker, extracted from the
/// wizard's schedule step so the Edit Plan window shows the identical controls.
struct ScheduleEditor: View {
    @Binding var kind: ScheduleKind
    @Binding var dailyTime: Date
    @Binding var weekday: Int

    /// Weekday numbers in the user's regional order (e.g. Monday-first in
    /// most of Europe and China), tagging the real Calendar weekday values.
    private var orderedWeekdays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        Picker("Frequency", selection: $kind) {
            ForEach(ScheduleKind.allCases) { kind in
                Text(kind.localizedTitle).tag(kind)
            }
        }
        .pickerStyle(.radioGroup)
        .labelsHidden()

        if kind == .weekly {
            Picker("On", selection: $weekday) {
                ForEach(orderedWeekdays, id: \.self) { day in
                    Text(Schedule.weekdayName(day)).tag(day)
                }
            }
            .frame(maxWidth: 200)
        }

        if kind != .hourly {
            DatePicker(
                "At",
                selection: $dailyTime,
                displayedComponents: .hourAndMinute
            )
            .frame(maxWidth: 200)
        }
    }
}
