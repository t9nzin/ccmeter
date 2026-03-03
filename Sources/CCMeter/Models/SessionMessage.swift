import Foundation

struct JSONLEntry: Decodable {
    let type: String
    let sessionId: String?
    let timestamp: String?
    let message: AssistantMessage?
}

struct AssistantMessage: Decodable {
    let id: String?
    let model: String?
    let stop_reason: String?
    let usage: TokenUsage?
}

struct TokenUsage: Decodable {
    let input_tokens: Int
    let output_tokens: Int
    let cache_creation_input_tokens: Int?
    let cache_read_input_tokens: Int?
}
