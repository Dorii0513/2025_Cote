//
//  GenerateTagUseCase.swift
//  Cote
//
//  Created by 김예림 on 9/4/25.
//

import Foundation

public protocol GenerateTagsUseCase {
    func generateTags(content: String) async throws -> [String]
}

public final class DefaultGenerateTagsUseCase: GenerateTagsUseCase {
    private let openAIService = OpenAIService()
    
    public init() {}
    
    public func generateTags(content: String) async throws -> [String] {
        let systemPrompt = TagPromptBuilder.buildPrompt()
        
        // OpenAI API 호출
        let result = try await openAIService.generateCompletion(
            systemPrompt: systemPrompt,
            userContent: content
        )
        
        // JSON 문자열 → [String] 변환
        if let data = result.data(using: .utf8) {
            do {
                return try JSONDecoder().decode([String].self, from: data)
            } catch {
                print("❌ JSON 파싱 실패: \(error)")
                return ["parse-error"]
            }
        }
        return ["empty-response"]
    }
    
    private struct TagPromptBuilder {
        static func buildPrompt() -> String {
            return """
    You are a tagging assistant.
    Generate up to 5 short, specific tags for the given text (code or notes).
    
    Rules:
    - Output must be ONLY a valid JSON array of strings.
    - Do not add any explanation, markdown, or formatting (no backticks).
    Example: ["tag1","tag2","tag3"]
    """
        }
    }
}
