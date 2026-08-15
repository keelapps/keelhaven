import Foundation
import KeelhavenCore
import Observation

/// Draft state for the Edit Plan window, seeded from the stored plan and
/// written back through `AppState.updatePlan` on Save.
@MainActor
@Observable
final class EditPlanModel {
    var name = ""
    var sourcePaths: [String] = []
    var excludePatterns: [String] = []
    var scheduleKind: ScheduleKind = .daily
    var dailyTime = Schedule.defaultDailyTime
    /// Scratch field for the exclude-pattern TextField.
    var newExcludePattern = ""

    func load(from plan: BackupPlan) {
        name = plan.name
        sourcePaths = plan.sourcePaths
        excludePatterns = plan.excludePatterns
        (scheduleKind, dailyTime) = plan.schedule.editorComponents
        newExcludePattern = ""
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !sourcePaths.isEmpty
    }

    func builtSchedule() -> Schedule {
        Schedule(kind: scheduleKind, dailyTime: dailyTime)
    }

    func addExcludePattern() {
        let trimmed = newExcludePattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !excludePatterns.contains(trimmed) else { return }
        excludePatterns.append(trimmed)
        newExcludePattern = ""
    }

    func removeExcludePattern(_ pattern: String) {
        excludePatterns.removeAll { $0 == pattern }
    }
}
