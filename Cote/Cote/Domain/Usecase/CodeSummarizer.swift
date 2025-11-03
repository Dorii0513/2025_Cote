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

/// A tiny helper that summarizes code into a single Korean sentence.
/// - Note: Uses SystemLanguageModel when available on the running OS. Falls back to a lightweight heuristic on earlier OS versions.
final class CodeSummarizer {

    /// Summarize the given Swift source as a single concise Korean sentence.
    /// - Parameter code: The Swift source to summarize.
    /// - Returns: A single-sentence Korean summary.
    func summarize(code: String) async throws -> String {
        // Use the on-device SystemLanguageModel only when it is available on the running OS.
#if canImport(FoundationModels)
        if #available(macOS 26.0, iOS 18.0, *) {
            let prompt = """
                    Summarize the following Swift code in one concise Korean sentence that describes what the code does:
                    \(code)
                    """
            // ✅ 1) 기본 시스템 언어 모델 가져오기
            let model = SystemLanguageModel.default
            
            let session = LanguageModelSession()
            
            // ✅ 3) 응답 요청
            let response = try await session.respond(to: prompt)
            
            // ✅ 4) 결과 텍스트 반환
            return response.content
        }
#endif

        // Fallback path for earlier OS versions or when FoundationModels is unavailable.
        // Provide a very simple heuristic summary to keep the app functional.
        return fallbackSummary(for: code)
    }

    // MARK: - Fallback

    private func fallbackSummary(for code: String) -> String {
        // Extremely lightweight heuristic: detect common Swift constructs and produce a short Korean sentence.
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

