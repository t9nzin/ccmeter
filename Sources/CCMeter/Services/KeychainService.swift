import Foundation

enum KeychainService {
    struct ClaudeKeychainData: Codable {
        let claudeAiOauth: ClaudeOAuthData
    }

    struct ClaudeOAuthData: Codable {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Double
        let subscriptionType: String?
    }

    /// Read the Claude Code OAuth access token from the macOS Keychain.
    /// Uses /usr/bin/security CLI to avoid triggering Keychain password dialogs.
    static func getAccessToken() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", Constants.Keychain.serviceName, "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }

        guard let jsonData = raw.data(using: .utf8),
              let keychainData = try? JSONDecoder().decode(ClaudeKeychainData.self, from: jsonData) else {
            return nil
        }

        return keychainData.claudeAiOauth.accessToken
    }
}
