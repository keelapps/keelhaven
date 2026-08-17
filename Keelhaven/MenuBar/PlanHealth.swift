import KeelhavenCore

/// A plan's at-a-glance health, distinct from `PlanRunState` because an idle
/// plan after a failed run and an idle plan that never ran both read as
/// "idle" there but need different colors/summaries here.
enum PlanHealth {
    case running
    case ok
    case neverBackedUp
    case needsAttention
}

extension BackupPlan {
    func health(runState: PlanRunState) -> PlanHealth {
        switch runState {
        case .running:
            return .running
        case .failed:
            return .needsAttention
        case .succeeded:
            return .ok
        case .idle:
            guard let lastRun else { return .neverBackedUp }
            return lastRun.success ? .ok : .needsAttention
        }
    }
}
