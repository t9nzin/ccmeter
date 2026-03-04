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

    // Polling intervals (seconds)
    static let defaultPollInterval: TimeInterval = 60.0
    static let minPollInterval: TimeInterval = 30.0
    static let maxPollInterval: TimeInterval = 300.0
}
