import Foundation
import Security

/// Minimal Keychain wrapper for personal data (ID numbers, addresses, bank details)
/// that previously sat unencrypted in UserDefaults.
enum KeychainStore {
    private static let service = Bundle.main.bundleIdentifier ?? "com.flightcompensation.app"

    static func data(for key: String) -> Data? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func set(_ data: Data, for key: String) -> Bool {
        let query = baseQuery(key)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            attributes.forEach { insert[$0.key] = $0.value }
            return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
        }
        return status == errSecSuccess
    }

    static func remove(_ key: String) {
        SecItemDelete(baseQuery(key) as CFDictionary)
    }

    /// Moves a value written by older app versions from UserDefaults into the Keychain.
    static func migrateFromUserDefaults(_ key: String) {
        guard let legacy = UserDefaults.standard.data(forKey: key) else { return }
        if data(for: key) == nil {
            set(legacy, for: key)
        }
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
