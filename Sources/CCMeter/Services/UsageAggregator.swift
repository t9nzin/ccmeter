import Foundation
import SwiftUI

@Observable
final class UsageAggregator {
    var usageData: UsageData?
    var lastError: String?
    var isLoading: Bool = false

    var sessionUtilization: Double {
        usageData?.fiveHour?.utilization ?? 0
    }

    var weeklyUtilization: Double {
        usageData?.sevenDay?.utilization ?? 0
    }

    var weeklyOpusUtilization: Double {
        usageData?.sevenDayOpus?.utilization ?? 0
    }

    var menuBarText: String {
        guard usageData != nil else { return "–" }
        return "\(Int(sessionUtilization.rounded()))%"
    }

    @ObservationIgnored
    private var fallbackTimer: Timer?

    @ObservationIgnored
    private var hookServer: HookServer?

    @ObservationIgnored
    private var lastFetchTime: Date?

    func start() {
        // Fetch immediately on launch
        Task { await fetchUsage() }

        // Fallback poll timer (safety net when hooks aren't configured)
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: Constants.fallbackPollInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.fetchUsage() }
        }

        // Start the hook server
        hookServer = HookServer { [weak self] in
            self?.hookTriggered()
        }
        hookServer?.start()
    }

    func stop() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        hookServer?.stop()
        hookServer = nil
    }

    /// Called by HookServer when a Claude Code hook event arrives.
    private func hookTriggered() {
        // Debounce: skip if we fetched too recently
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < Constants.hookDebounceInterval {
            return
        }

        Task { await fetchUsage() }
    }

    @MainActor
    func fetchUsage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await APIService.fetchUsage()
            usageData = data
            lastError = nil
            lastFetchTime = Date()
        } catch {
            lastError = describeError(error)
        }
    }

    private func describeError(_ error: Error) -> String {
        if let apiError = error as? APIService.APIError {
            switch apiError {
            case .noToken:
                return "No Claude login found. Run 'claude login' first."
            case .invalidURL:
                return "Invalid API URL"
            case .requestFailed(let code):
                return "API error (\(code))"
            case .decodingFailed:
                return "Failed to parse usage data"
            }
        }
        return error.localizedDescription
    }
}
