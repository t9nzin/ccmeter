import Foundation

struct UsageSnapshot {
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheCreationTokens: Int = 0
    var cacheReadTokens: Int = 0

    mutating func add(_ usage: TokenUsage) {
        inputTokens += usage.input_tokens
        outputTokens += usage.output_tokens
        cacheCreationTokens += usage.cache_creation_input_tokens ?? 0
        cacheReadTokens += usage.cache_read_input_tokens ?? 0
    }
}

struct ParsedUsageLine {
    let sessionId: String?
    let timestamp: Date?
    let usage: TokenUsage
}
