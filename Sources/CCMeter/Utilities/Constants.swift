import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://api.anthropic.com"
        static let usageEndpoint = "/api/oauth/usage"
        static let anthropicBeta = "oauth-2025-04-20"
    }

    enum Keychain {
        static let serviceName = "Claude Code-credentials"
    }

    // Fallback polling interval (seconds) — used when hooks aren't configured
    static let fallbackPollInterval: TimeInterval = 300.0

    // Hook server
    static let hookServerPort: UInt16 = 19199
    static let hookDebounceInterval: TimeInterval = 2.0
}
