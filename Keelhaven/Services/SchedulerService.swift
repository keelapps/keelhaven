import Foundation

/// Fires a callback once a minute while the app is resident in the menu bar.
/// The callback asks SchedulePolicy which plans are due. The upgrade path to
/// a launchd agent (runs without the app open) reuses the same policy.
final class SchedulerService {
    private var timer: DispatchSourceTimer?

    func start(interval: TimeInterval = 60, onTick: @escaping @Sendable () -> Void) {
        stop()
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler(handler: onTick)
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        stop()
    }
}
