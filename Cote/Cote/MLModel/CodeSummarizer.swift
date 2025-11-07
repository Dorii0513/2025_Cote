//
//  CodeSummarizer.swift
//  Cote
//
//  Created by 김예림 on 11/3/25.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

final class CodeSummarizer {
    private var isSummarizing = false
    
    func summarize(code: String) async throws -> String {
#if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 18.0, *) {
            
            //프롬프트
            let prompt = """
            Summarize the following code in two concise sentences optimized for search:
            1) A Korean summary.
            2) An English summary.

            Each summary must clearly describe the code’s main purpose, behavior, and role so the note can be easily found through semantic search.

            Code:
            \(code)
            """
            
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            
            print(response.content)
            
            // 반환
            return response.content
        }
#endif
        return fallbackSummary(for: code)
    }

    // MARK: - Fallback

    private func fallbackSummary(for code: String) -> String {
        let lower = code.lowercased()
        if lower.contains("class ") { return "이 코드는 하나 이상의 클래스를 정의합니다." }
        if lower.contains("struct ") { return "이 코드는 하나 이상의 구조체를 정의합니다." }
        if lower.contains("enum ") { return "이 코드는 하나 이상의 열거형을 정의합니다." }
        if lower.contains("func ") { return "이 코드는 하나 이상의 함수를 구현합니다." }
        if lower.contains("actor ") { return "이 코드는 동시성을 위한 액터를 정의합니다." }
        if lower.contains("async ") || lower.contains("await") { return "이 코드는 비동기 작업을 수행합니다." }
        if lower.contains("@main") { return "이 코드는 앱의 진입점을 제공합니다." }
        return "이 코드는 Swift 로직을 구현합니다."
    }
}

