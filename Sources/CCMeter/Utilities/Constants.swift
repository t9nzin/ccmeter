import Foundation

enum Constants {
    static let claudeProjectsPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/projects"
    }()

    // Pro plan defaults
    static let defaultSessionOutputTokenLimit = 300_000
    static let defaultWeeklyOutputTokenLimit = 3_500_000

    // Timing
    static let pollInterval: TimeInterval = 2.0
    static let directoryScanInterval: TimeInterval = 30.0
    static let weeklyRescanInterval: TimeInterval = 300.0 // 5 minutes

    // Storage keys
    static let sessionTokenLimitKey = "sessionTokenLimit"
    static let weeklyTokenLimitKey = "weeklyTokenLimit"
}
