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

    // Polling interval (seconds)
    static let pollInterval: TimeInterval = 120.0
}
