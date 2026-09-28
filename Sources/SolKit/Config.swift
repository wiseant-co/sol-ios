import Foundation

/// Shared config, stored in the App Group so the host app and the keyboard extension read the same
/// values. The host app writes the proxy URL, the account token, and the chosen language; the
/// keyboard reads them. No provider key ever lives on the device — the proxy holds those.
public struct SolConfig {
    public static let appGroup = "group.co.wiseant.sol"

    public var proxyURL: URL
    public var token: String
    public var language: String   // multi | ta | hi | te | en …

    private static let defaults = UserDefaults(suiteName: appGroup)

    public static func load() -> SolConfig {
        let d = defaults
        let urlString = d?.string(forKey: "proxyURL") ?? "https://your-sol-proxy.example.com"
        return SolConfig(
            proxyURL: URL(string: urlString) ?? URL(string: "https://your-sol-proxy.example.com")!,
            token: d?.string(forKey: "token") ?? "",
            language: d?.string(forKey: "language") ?? "multi"
        )
    }

    public static func save(proxyURL: String, token: String, language: String) {
        let d = defaults
        d?.set(proxyURL, forKey: "proxyURL")
        d?.set(token, forKey: "token")
        d?.set(language, forKey: "language")
    }

    /// True once the host app has stored a proxy URL + token — the keyboard shows a hint otherwise.
    public var isConfigured: Bool { !token.isEmpty }
}
