import Foundation
#if canImport(Security)
import Security

/// Real Keychain-backed secret storage. Items are generic passwords under a
/// single service name, readable after first unlock so scheduled backups can
/// run unattended after a reboot login.
public struct KeychainStore: KeychainStoring {
    public static let service = "com.keelhaven.app"

    /// Seam over the raw SecItem calls so the status-handling logic is
    /// testable without touching the real keychain. `.live` binds the actual
    /// Security functions; tests inject stubs returning canned statuses.
    /// `@unchecked` because the C functions carry no Sendable annotation but
    /// are thread-safe, and test stubs are pure.
    struct SecItemClient: @unchecked Sendable {
        var update: (CFDictionary, CFDictionary) -> OSStatus
        var add: (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
        var copyMatching: (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
        var delete: (CFDictionary) -> OSStatus

        static let live = SecItemClient(
            update: SecItemUpdate,
            add: SecItemAdd,
            copyMatching: SecItemCopyMatching,
            delete: SecItemDelete
        )
    }

    private let client: SecItemClient

    public init() {
        self.init(client: .live)
    }

    init(client: SecItemClient) {
        self.client = client
    }

    public func setSecret(_ secret: String, account: String) throws {
        let data = Data(secret.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
        ]

        let update: [String: Any] = [
            kSecValueData as String: data,
        ]

        let updateStatus = client.update(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = client.add(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    public func secret(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = client.copyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let secret = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return secret
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func deleteSecret(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
        ]

        let status = client.delete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
#endif
