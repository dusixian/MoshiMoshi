//
//  KeychainHelper.swift
//  MoshiMoshi
//
//  Secure storage for auth token and user identifier (no "database" — Keychain only).
//

import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.moshimoshi.app"

    static func save(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(data, for: key)
    }

    static func save(_ value: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]
        SecItemDelete(query as CFDictionary) // remove old if exists
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func loadString(for key: String) -> String? {
        guard let data = loadData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func loadData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return data
    }

    static func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    /// Removes all items we stored (used on sign out).
    static func clearAuthKeys() {
        _ = delete(for: KeychainKeys.appleUserIdentifier)
        _ = delete(for: KeychainKeys.backendToken)
        _ = delete(for: KeychainKeys.userName)
        _ = delete(for: KeychainKeys.userEmail)
    }

    enum KeychainKeys {
        static let appleUserIdentifier = "appleUserIdentifier"
        static let backendToken = "backendToken"
        static let userName = "userName"
        static let userEmail = "userEmail"
    }
}
