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
    private var pollTimer: Timer?

    func start() {
        // Fetch immediately on launch
        Task { await fetchUsage() }

        // Start polling
        pollTimer = Timer.scheduledTimer(withTimeInterval: Constants.pollInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.fetchUsage() }
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    @MainActor
    func fetchUsage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await APIService.fetchUsage()
            usageData = data
            lastError = nil
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
