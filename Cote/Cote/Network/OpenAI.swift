//
//  OpenAI.swift
//  Cote
//
//  Created by 김예림 on 9/2/25.
//

import Foundation
import AppKit

// MARK: - OpenAI Service
class OpenAIService {
    private let apiKey: String?
    
    init() {
        self.apiKey = APIKeyLoader.loadOpenAIKey()
    }
    
    func generateCompletion(systemPrompt: String, userContent: String) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIServiceError.invalidURL
        }
        
        let request = try buildRequest(url: url, apiKey: apiKey, systemPrompt: systemPrompt, userContent: userContent)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try validateResponse(response, data: data)
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? ""
    }
    
    private func buildRequest(url: URL, apiKey: String, systemPrompt: String, userContent: String) throws -> URLRequest {
        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            temperature: 0.2,
            max_tokens: 200
        )
        
        let data = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = data
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ OpenAI HTTP \(httpResponse.statusCode): \(body)")
            throw OpenAIServiceError.httpError(httpResponse.statusCode, body)
        }
    }
}

// MARK: - OpenAI Service Models
struct ChatRequest: Codable {
    let model: String
    let messages: [[String: String]]
    let temperature: Double
    let max_tokens: Int
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let index: Int?
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - OpenAI Service Errors
enum OpenAIServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not found in Key.plist"
        case .invalidURL:
            return "Invalid OpenAI API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .httpError(let code, let message):
            return "HTTP Error \(code): \(message)"
        }
    }
}

// MARK: - API Key Loader
struct APIKeyLoader {
    static func loadOpenAIKey() -> String? {
        guard let fileURL = Bundle.main.url(forResource: "Key", withExtension: "plist"),
              let data = try? Data(contentsOf: fileURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let apiKey = plist["OpenAI_Key"] as? String else {
            print("⚠️ OPENAI_API_KEY not found in Key.plist under 'OpenAI_Key'")
            return nil
        }
        
        return apiKey
    }
}
