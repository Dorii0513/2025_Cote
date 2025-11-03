//
//  SummarizerTest.swift
//  Cote
//
//  Created by 김예림 on 11/3/25.
//

import Foundation

//@main
struct SummarizerTest {
    static func main() async {
        let summarizer = CodeSummarizer()
        do {
            let code = """
            func calculateTotal(price: Double, quantity: Int) -> Double {
                return price * Double(quantity)
            }
            """
            let summary = try await summarizer.summarize(code: code)
            print("🧩 요약 결과:", summary)
        } catch {
            print("❌ 에러:", error)
        }
    }
}
