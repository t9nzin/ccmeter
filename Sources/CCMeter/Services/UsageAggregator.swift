import Foundation
import SwiftUI

@Observable
final class UsageAggregator {
    var sessionOutputTokens: Int = 0
    var weeklyOutputTokens: Int = 0
    var activeSessionId: String?
    var isSessionActive: Bool = false

    var sessionTokenLimit: Int {
        didSet { UserDefaults.standard.set(sessionTokenLimit, forKey: Constants.sessionTokenLimitKey) }
    }
    var weeklyTokenLimit: Int {
        didSet { UserDefaults.standard.set(weeklyTokenLimit, forKey: Constants.weeklyTokenLimitKey) }
    }

    @ObservationIgnored
    private let watcher = SessionWatcher()

    @ObservationIgnored
    private var weeklyRescanTimer: Timer?

    @ObservationIgnored
    private var sessionUsage = UsageSnapshot()

    @ObservationIgnored
    private var weeklyUsage = UsageSnapshot()

    init() {
        let defaults = UserDefaults.standard
        let savedSession = defaults.integer(forKey: Constants.sessionTokenLimitKey)
        let savedWeekly = defaults.integer(forKey: Constants.weeklyTokenLimitKey)
        self.sessionTokenLimit = savedSession > 0 ? savedSession : Constants.defaultSessionOutputTokenLimit
        // Migrate from old 1.5M default to new 3.5M default
        if savedWeekly == 1_500_000 || savedWeekly == 0 {
            self.weeklyTokenLimit = Constants.defaultWeeklyOutputTokenLimit
        } else {
            self.weeklyTokenLimit = savedWeekly
        }
    }

    var sessionPercentage: Double {
        guard sessionTokenLimit > 0 else { return 0 }
        return min(Double(sessionOutputTokens) / Double(sessionTokenLimit), 1.0)
    }

    var weeklyPercentage: Double {
        guard weeklyTokenLimit > 0 else { return 0 }
        return min(Double(weeklyOutputTokens) / Double(weeklyTokenLimit), 1.0)
    }

    var menuBarText: String {
        "\(Int(weeklyPercentage * 100))%"
    }

    func start() {
        // Initial weekly scan
        performWeeklyScan()

        // Set up watcher callbacks
        watcher.onActiveSessionChanged = { [weak self] sessionId in
            guard let self else { return }
            self.activeSessionId = sessionId
            self.isSessionActive = sessionId != nil

            // Reset session counter for new session
            self.sessionUsage = UsageSnapshot()
            self.sessionOutputTokens = 0

            // Parse the active session fully to get its current usage
            if let sessionId {
                self.loadActiveSessionUsage(sessionId)
            }
        }

        watcher.onUsageUpdate = { [weak self] _, lines in
            guard let self else { return }
            for line in lines {
                self.sessionUsage.add(line.usage)
                self.weeklyUsage.add(line.usage)
            }
            self.sessionOutputTokens = self.sessionUsage.outputTokens
            self.weeklyOutputTokens = self.weeklyUsage.outputTokens
        }

        watcher.start()

        // Periodic full weekly rescan
        weeklyRescanTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.weeklyRescanInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performWeeklyScan()
        }
    }

    func stop() {
        watcher.stop()
        weeklyRescanTimer?.invalidate()
        weeklyRescanTimer = nil
    }

    private func performWeeklyScan() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let (perSession, total) = watcher.scanAllFiles(since: cutoff)

        weeklyUsage = total
        weeklyOutputTokens = total.outputTokens

        // If there's an active session, load its usage
        if let activeId = watcher.getActiveSessionId() {
            activeSessionId = activeId
            isSessionActive = true
            if let sessionSnap = perSession[activeId] {
                sessionUsage = sessionSnap
                sessionOutputTokens = sessionSnap.outputTokens
            }
        }
    }

    private func loadActiveSessionUsage(_ sessionId: String) {
        // The session watcher already parsed the file during scan,
        // so the tracked file's usage is our session usage.
        // We just need to find files matching this session ID.
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(atPath: Constants.claudeProjectsPath) else { return }

        var snapshot = UsageSnapshot()
        for dir in projectDirs {
            let filePath = "\(Constants.claudeProjectsPath)/\(dir)/\(sessionId).jsonl"
            if let usage = watcher.getTrackedUsage(for: filePath) {
                snapshot.inputTokens += usage.inputTokens
                snapshot.outputTokens += usage.outputTokens
                snapshot.cacheCreationTokens += usage.cacheCreationTokens
                snapshot.cacheReadTokens += usage.cacheReadTokens
            }

            // Also check subagents
            let subagentDir = "\(Constants.claudeProjectsPath)/\(dir)/\(sessionId)/subagents"
            guard let subFiles = try? fm.contentsOfDirectory(atPath: subagentDir) else { continue }
            for subFile in subFiles where subFile.hasSuffix(".jsonl") {
                let subPath = "\(subagentDir)/\(subFile)"
                if let usage = watcher.getTrackedUsage(for: subPath) {
                    snapshot.inputTokens += usage.inputTokens
                    snapshot.outputTokens += usage.outputTokens
                    snapshot.cacheCreationTokens += usage.cacheCreationTokens
                    snapshot.cacheReadTokens += usage.cacheReadTokens
                }
            }
        }

        sessionUsage = snapshot
        sessionOutputTokens = snapshot.outputTokens
    }
}
