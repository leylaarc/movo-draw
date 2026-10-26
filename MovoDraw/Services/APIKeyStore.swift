import Foundation
import Security

/// Resolves API keys without committing secrets.
/// Priority: process environment → Keychain → (never Info.plist / never source).
enum APIKeyStore {
    enum Provider: String {
        case fal = "FAL_KEY"
        case openAI = "OPENAI_API_KEY"
        case movoAlias = "MOVO_DRAW_API_KEY"
        case replicate = "REPLICATE_API_TOKEN"
    }

    static func falKey() -> String? {
        firstPresent([.fal, .movoAlias])
    }

    static func openAIKey() -> String? {
        value(for: .openAI)
    }

    static func hasAnyCloudKey() -> Bool {
        falKey() != nil || openAIKey() != nil || value(for: .replicate) != nil
    }

    static func firstPresent(_ keys: [Provider]) -> String? {
        for key in keys {
            if let v = value(for: key) { return v }
        }
        return nil
    }

    static func value(for provider: Provider) -> String? {
        if let env = ProcessInfo.processInfo.environment[provider.rawValue], !env.isEmpty {
            return env
        }
        return readKeychain(account: provider.rawValue)
    }

    /// Optional: `security add-generic-password -a FAL_KEY -s com.movodraw.app -w '…'`
    static func saveToKeychain(_ secret: String, provider: Provider) -> Bool {
        let account = provider.rawValue
        let data = Data(secret.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.movodraw.app",
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    private static func readKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.movodraw.app",
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
