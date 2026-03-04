import Foundation

enum APIService {
    enum APIError: Error {
        case noToken
        case invalidURL
        case requestFailed(Int)
        case decodingFailed
    }

    /// Fetch usage data from the Anthropic OAuth usage API.
    static func fetchUsage() async throws -> UsageData {
        guard let token = KeychainService.getAccessToken() else {
            throw APIError.noToken
        }

        guard let url = URL(string: Constants.API.baseURL + Constants.API.usageEndpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.API.anthropicBeta, forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(0)
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let usageData = try? decoder.decode(UsageData.self, from: data) else {
            throw APIError.decodingFailed
        }

        return usageData
    }
}
