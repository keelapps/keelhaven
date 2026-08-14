import Foundation
import LocalAuthentication

/// Gates sensitive interactive actions (revealing a backup password, deleting
/// a plan) behind Touch ID. Scheduled backups deliberately do NOT use this —
/// they must run unattended.
enum BiometricAuthService {
    /// Touch ID on capable Macs; macOS falls back to the login password on
    /// Macs without it (or with the lid closed), so this works everywhere.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
