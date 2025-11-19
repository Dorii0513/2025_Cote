//
//  GenerateCommentUseCase.swift
//  Cote
//
//  Created by 김예림 on 11/19/25.
//

import Foundation
import FoundationModels

protocol GenerateCommentUseCase {
    func execute(code: String) async throws -> [AIComment]
}

@MainActor
struct DefaultGenerateCommentUseCase: GenerateCommentUseCase {
    
    private let openAIService = OpenAIService()
    
    func execute(code: String) async throws -> [AIComment] {
        return try await executeWithOpenAI(code: code)
    }
    
    private func executeWithOpenAI(code: String) async throws -> [AIComment] {
        let systemPrompt = """
            당신은 코드 리뷰어입니다. 코드를 분석하여 개발자에게 유용한 주석을 달아주세요.
            코드의 전체 로직을 파악한 후, 함수가 어떤 역할을 하고 있는 지 
            또는, 각각의 코드가 해당 함수의 역할을 수행하기 위해 어떠한 과정을 거치고 있는지 달아주세요.
            
            중요 규칙:
            1. 코드 왼쪽에 표시된 줄 번호를 정확히 사용하세요.
            2. 빈 줄도 줄 번호에 포함됩니다.
            3. 간단한 UI 코드에는 주석을 달지 마세요.
            4. 복잡한 로직이 있을 때만 주석을 다세요.
            
            만약 주석을 달 만한 코드가 없다면 빈 배열을 반환하세요: { "comments": [] }
            
            응답 형식 예시입니다. 참고로만 보세요. (JSON만):
            {
              "comments": [
                { "line": 15, "comment": "드래그 델타 계산" }
              ]
            }
            
            - line: 왼쪽에 표시된 정확한 줄 번호
            - comment: "//"를 제외한 주석 내용만
            """
        
        // 코드에 줄 번호 추가
        let numberedCode = addLineNumbers(to: code)
        
        let userContent = """
        다음 Swift 코드를 분석하고 의미있는 주석을 JSON 형식으로만 반환하세요.
        왼쪽 숫자는 줄 번호입니다. 이 번호를 정확히 사용하세요.
        
        \(numberedCode)
        
        JSON만 출력하세요. 다른 텍스트는 포함하지 마세요.
        """
        
        let response = try await openAIService.generateCompletion(
            systemPrompt: systemPrompt,
            userContent: userContent
        )
        
        print("=== OpenAI 원본 응답 ===")
        print(response)
        print("==================")
        
        // JSON 추출 및 정제
        let jsonString = cleanJSONResponse(response)
        
        print("=== 정제된 JSON ===")
        print(jsonString)
        print("==================")
        
        let decoded = try parseComments(from: jsonString)
        let totalLines = code.split(separator: "\n", omittingEmptySubsequences: false).count
        
        let mapped: [AIComment] = decoded.comments
            .filter { $0.line >= 1 && $0.line <= totalLines }
            .map { c in
                AIComment(
                    id: UUID(),
                    line: c.line,
                    text: "// " + c.comment
                )
            }
        
        return mapped
    }
}

// 줄 번호 추가 함수
private func addLineNumbers(to code: String) -> String {
    let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
    let numbered = lines.enumerated().map { index, line in
        let lineNumber = String(format: "%3d", index + 1)
        return "\(lineNumber) | \(line)"
    }
    return numbered.joined(separator: "\n")
}

private func parseComments(from jsonString: String) throws -> AICommentResponse {
    var trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
    
    func decode(_ s: String) -> AICommentResponse? {
        guard let data = s.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AICommentResponse.self, from: data)
    }
    
    if let decoded = decode(trimmed) {
        return decoded
    }
    
    let lines = trimmed.split(separator: "\n")
    var objectLines: [Substring] = []
    for line in lines {
        let l = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if l.contains("\"line\""),
           l.contains("\"comment\""),
           l.contains("}") {
            objectLines.append(line)
        }
    }
    
    guard !objectLines.isEmpty else {
        throw GenerateCommentError.invalidResponse
    }
    
    if var last = objectLines.last {
        let t = last.trimmingCharacters(in: .whitespaces)
        if t.hasSuffix(",") {
            last = Substring(t.dropLast())
            objectLines[objectLines.count - 1] = last
        }
    }
    
    // 다시 JSON 구성
    let objectsJoined = objectLines.joined(separator: "\n")
    let rebuiltJSON = """
    {
      "comments": [
    \(objectsJoined)
      ]
    }
    """
    
    guard let rebuiltData = rebuiltJSON.data(using: .utf8) else {
        throw GenerateCommentError.invalidResponse
    }
    
    do {
        return try JSONDecoder().decode(AICommentResponse.self, from: rebuiltData)
    } catch {
        print("⚠️ JSON 디코드 실패(복구 후): \(error)")
        print("⚠️ 복구 JSON:")
        print(rebuiltJSON)
        throw GenerateCommentError.invalidResponse
    }
}

private func cleanJSONResponse(_ response: String) -> String {
    var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // 마크다운 코드 블록 제거
    if cleaned.hasPrefix("```json") {
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
    }
    if cleaned.hasPrefix("```") {
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
    }
    if cleaned.hasSuffix("```") {
        cleaned = String(cleaned.dropLast(3))
    }
    
    // 앞뒤 공백 다시 제거
    cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // JSON 시작/끝 찾기
    if let jsonStart = cleaned.firstIndex(of: "{"),
       let jsonEnd = cleaned.lastIndex(of: "}") {
        cleaned = String(cleaned[jsonStart...jsonEnd])
    }
    
    return cleaned
}

enum GenerateCommentError: LocalizedError {
    case invalidResponse
    case unsupportedOS
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "AI 응답을 파싱할 수 없습니다."
        case .unsupportedOS:
            return "이 기능은 macOS 26.0 이상에서만 사용할 수 있습니다."
        }
    }
}
