import Foundation

/// Watches Claude Code JSONL session files for changes and reports new usage data.
final class SessionWatcher {
    struct TrackedFile {
        let url: URL
        var offset: UInt64
        var usage: UsageSnapshot
    }

    private let projectsPath: String
    private var trackedFiles: [String: TrackedFile] = [:] // keyed by file path
    private var activeSessionId: String?
    private var activeSessionFile: URL?

    private var pollTimer: Timer?
    private var dirScanTimer: Timer?
    private var fileSource: DispatchSourceFileSystemObject?
    private var watchedFD: Int32 = -1

    var onUsageUpdate: ((String?, [ParsedUsageLine]) -> Void)?
    var onActiveSessionChanged: ((String?) -> Void)?

    init(projectsPath: String = Constants.claudeProjectsPath) {
        self.projectsPath = projectsPath
    }

    func start() {
        scanForSessions()
        startPolling()
        startDirectoryScan()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        dirScanTimer?.invalidate()
        dirScanTimer = nil
        stopFileWatch()
    }

    // MARK: - Directory Scanning

    /// Find all JSONL files, identify the active session (most recently modified).
    func scanForSessions() {
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(atPath: projectsPath) else { return }

        var mostRecentDate = Date.distantPast
        var mostRecentFile: URL?
        var mostRecentSessionId: String?

        for dir in projectDirs {
            let dirPath = "\(projectsPath)/\(dir)"
            guard let files = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }

            for file in files {
                guard file.hasSuffix(".jsonl") else { continue }
                let filePath = "\(dirPath)/\(file)"
                let fileURL = URL(fileURLWithPath: filePath)

                guard let attrs = try? fm.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date else { continue }

                let sessionId = String(file.dropLast(6)) // remove .jsonl

                if modDate > mostRecentDate {
                    mostRecentDate = modDate
                    mostRecentFile = fileURL
                    mostRecentSessionId = sessionId
                }
            }

            // Also check subagent directories
            for file in files where !file.hasSuffix(".jsonl") {
                let subagentDir = "\(dirPath)/\(file)/subagents"
                guard let subFiles = try? fm.contentsOfDirectory(atPath: subagentDir) else { continue }
                for subFile in subFiles where subFile.hasSuffix(".jsonl") {
                    let subPath = "\(subagentDir)/\(subFile)"
                    let subURL = URL(fileURLWithPath: subPath)
                    // Track subagent files but don't use them for active session detection
                    if trackedFiles[subPath] == nil {
                        trackedFiles[subPath] = TrackedFile(url: subURL, offset: 0, usage: UsageSnapshot())
                    }
                }
            }
        }

        if let newSessionId = mostRecentSessionId, newSessionId != activeSessionId {
            activeSessionId = newSessionId
            activeSessionFile = mostRecentFile
            onActiveSessionChanged?(newSessionId)

            if let file = mostRecentFile {
                watchFile(file)
            }

            // Find and track subagent files for this session
            if let file = mostRecentFile {
                let sessionDir = file.deletingLastPathComponent()
                    .appendingPathComponent(newSessionId)
                    .appendingPathComponent("subagents")
                if let subFiles = try? fm.contentsOfDirectory(atPath: sessionDir.path) {
                    for subFile in subFiles where subFile.hasSuffix(".jsonl") {
                        let subPath = sessionDir.appendingPathComponent(subFile).path
                        if trackedFiles[subPath] == nil {
                            trackedFiles[subPath] = TrackedFile(
                                url: URL(fileURLWithPath: subPath),
                                offset: 0,
                                usage: UsageSnapshot()
                            )
                        }
                    }
                }
            }
        }

        // Track the active session file
        if let file = mostRecentFile, trackedFiles[file.path] == nil {
            trackedFiles[file.path] = TrackedFile(url: file, offset: 0, usage: UsageSnapshot())
        }
    }

    // MARK: - File Watching

    private func watchFile(_ url: URL) {
        stopFileWatch()

        let fd = open(url.path, O_RDONLY | O_EVTONLY)
        guard fd >= 0 else { return }
        watchedFD = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.pollActiveFiles()
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        fileSource = source
    }

    private func stopFileWatch() {
        fileSource?.cancel()
        fileSource = nil
        watchedFD = -1
    }

    // MARK: - Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: Constants.pollInterval, repeats: true) { [weak self] _ in
            self?.pollActiveFiles()
        }
    }

    private func startDirectoryScan() {
        dirScanTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.directoryScanInterval,
            repeats: true
        ) { [weak self] _ in
            self?.scanForSessions()
        }
    }

    /// Read new bytes from all tracked files and emit parsed usage lines.
    func pollActiveFiles() {
        for (path, tracked) in trackedFiles {
            let (lines, newOffset) = JSONLParser.parseFile(at: tracked.url, fromOffset: tracked.offset)
            if newOffset > tracked.offset {
                trackedFiles[path]?.offset = newOffset
                for line in lines {
                    trackedFiles[path]?.usage.add(line.usage)
                }
                if !lines.isEmpty {
                    onUsageUpdate?(activeSessionId, lines)
                }
            }
        }
    }

    // MARK: - Historical Scanning

    /// Scan all JSONL files and return usage for a given time window.
    func scanAllFiles(since cutoff: Date) -> (perSession: [String: UsageSnapshot], total: UsageSnapshot) {
        let fm = FileManager.default
        var perSession: [String: UsageSnapshot] = [:]
        var total = UsageSnapshot()

        guard let projectDirs = try? fm.contentsOfDirectory(atPath: projectsPath) else {
            return (perSession, total)
        }

        for dir in projectDirs {
            let dirPath = "\(projectsPath)/\(dir)"
            guard let files = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }

            for file in files where file.hasSuffix(".jsonl") {
                let filePath = "\(dirPath)/\(file)"
                let fileURL = URL(fileURLWithPath: filePath)

                // Skip files not modified since cutoff
                guard let attrs = try? fm.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date,
                      modDate >= cutoff else { continue }

                let sessionId = String(file.dropLast(6))
                let (lines, offset) = JSONLParser.parseFile(at: fileURL, fromOffset: 0)

                // Update tracked file state
                var snapshot = UsageSnapshot()
                for line in lines {
                    // Only count lines within the time window
                    if let ts = line.timestamp, ts >= cutoff {
                        snapshot.add(line.usage)
                    }
                }
                perSession[sessionId, default: UsageSnapshot()].inputTokens += snapshot.inputTokens
                perSession[sessionId, default: UsageSnapshot()].outputTokens += snapshot.outputTokens
                perSession[sessionId, default: UsageSnapshot()].cacheCreationTokens += snapshot.cacheCreationTokens
                perSession[sessionId, default: UsageSnapshot()].cacheReadTokens += snapshot.cacheReadTokens
                total.inputTokens += snapshot.inputTokens
                total.outputTokens += snapshot.outputTokens
                total.cacheCreationTokens += snapshot.cacheCreationTokens
                total.cacheReadTokens += snapshot.cacheReadTokens

                // Cache offset for future incremental reads
                trackedFiles[filePath] = TrackedFile(url: fileURL, offset: offset, usage: snapshot)
            }

            // Also scan subagent files
            for file in files where !file.hasSuffix(".jsonl") {
                let subagentDir = "\(dirPath)/\(file)/subagents"
                guard let subFiles = try? fm.contentsOfDirectory(atPath: subagentDir) else { continue }
                for subFile in subFiles where subFile.hasSuffix(".jsonl") {
                    let subPath = "\(subagentDir)/\(subFile)"
                    let subURL = URL(fileURLWithPath: subPath)

                    guard let attrs = try? fm.attributesOfItem(atPath: subPath),
                          let modDate = attrs[.modificationDate] as? Date,
                          modDate >= cutoff else { continue }

                    let (lines, offset) = JSONLParser.parseFile(at: subURL, fromOffset: 0)
                    var snapshot = UsageSnapshot()
                    for line in lines {
                        if let ts = line.timestamp, ts >= cutoff {
                            snapshot.add(line.usage)
                        }
                    }

                    let parentSessionId = file
                    perSession[parentSessionId, default: UsageSnapshot()].inputTokens += snapshot.inputTokens
                    perSession[parentSessionId, default: UsageSnapshot()].outputTokens += snapshot.outputTokens
                    perSession[parentSessionId, default: UsageSnapshot()].cacheCreationTokens += snapshot.cacheCreationTokens
                    perSession[parentSessionId, default: UsageSnapshot()].cacheReadTokens += snapshot.cacheReadTokens
                    total.inputTokens += snapshot.inputTokens
                    total.outputTokens += snapshot.outputTokens
                    total.cacheCreationTokens += snapshot.cacheCreationTokens
                    total.cacheReadTokens += snapshot.cacheReadTokens

                    trackedFiles[subPath] = TrackedFile(url: subURL, offset: offset, usage: snapshot)
                }
            }
        }

        return (perSession, total)
    }

    func getActiveSessionId() -> String? { activeSessionId }
    func getTrackedUsage(for path: String) -> UsageSnapshot? { trackedFiles[path]?.usage }
}
