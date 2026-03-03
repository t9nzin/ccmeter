import Foundation

enum JSONLParser {
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Parse a single JSONL line into usage data if it's a completed assistant message.
    /// Returns nil for non-assistant lines, streaming intermediates (stop_reason == null), or parse errors.
    static func parseUsageLine(_ data: Data) -> ParsedUsageLine? {
        // Fast rejection: ~94% of lines are "type":"progress" — check for "type":"assistant" substring
        guard let str = String(data: data, encoding: .utf8),
              str.contains("\"type\":\"assistant\"") else {
            return nil
        }

        guard let entry = try? decoder.decode(JSONLEntry.self, from: data),
              entry.type == "assistant",
              let message = entry.message,
              message.stop_reason != nil,
              let usage = message.usage else {
            return nil
        }

        let timestamp: Date?
        if let ts = entry.timestamp {
            timestamp = iso8601Formatter.date(from: ts)
        } else {
            timestamp = nil
        }

        return ParsedUsageLine(
            sessionId: entry.sessionId,
            timestamp: timestamp,
            usage: usage
        )
    }

    /// Incrementally parse a JSONL file from a byte offset.
    /// Returns parsed usage lines and the new offset to resume from.
    static func parseFile(at url: URL, fromOffset: UInt64) -> (lines: [ParsedUsageLine], newOffset: UInt64) {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return ([], fromOffset)
        }
        defer { try? handle.close() }

        let fileSize: UInt64
        do {
            try handle.seek(toOffset: 0)
            _ = try handle.seekToEnd()
            fileSize = try handle.offset()
        } catch {
            return ([], fromOffset)
        }

        guard fileSize > fromOffset else {
            return ([], fromOffset)
        }

        do {
            try handle.seek(toOffset: fromOffset)
        } catch {
            return ([], fromOffset)
        }

        guard let newData = try? handle.readToEnd(), !newData.isEmpty else {
            return ([], fromOffset)
        }

        var results: [ParsedUsageLine] = []
        let newline = UInt8(ascii: "\n")
        var lineStart = newData.startIndex
        var lastCompleteLineEnd = newData.startIndex

        for i in newData.indices {
            if newData[i] == newline {
                let lineData = newData[lineStart..<i]
                if !lineData.isEmpty, let parsed = parseUsageLine(Data(lineData)) {
                    results.append(parsed)
                }
                lastCompleteLineEnd = newData.index(after: i)
                lineStart = lastCompleteLineEnd
            }
        }

        // Only advance offset to end of last complete line (don't consume partial lines)
        let bytesConsumed = UInt64(newData.distance(from: newData.startIndex, to: lastCompleteLineEnd))
        return (results, fromOffset + bytesConsumed)
    }
}
