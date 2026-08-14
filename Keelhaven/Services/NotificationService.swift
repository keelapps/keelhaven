import Foundation
import UserNotifications
import KeelhavenCore

enum NotificationService {
    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    static func postBackupFinished(planName: String, summary: BackupSummary?) async {
        let content = UNMutableNotificationContent()
        content.title = "Backup complete"
        if let summary {
            let added = ByteCountFormatter.string(
                fromByteCount: summary.dataAdded ?? 0,
                countStyle: .file
            )
            content.body = "\(planName): \(summary.filesNew) new files, \(added) added."
        } else {
            content.body = "\(planName) finished successfully."
        }
        await post(content)
    }

    static func postBackupFailed(planName: String, message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Backup failed"
        content.body = "\(planName): \(message)"
        content.sound = .default
        await post(content)
    }

    private static func post(_ content: UNMutableNotificationContent) async {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
