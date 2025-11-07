//
//  CoteTests.swift
//  CoteTests
//
//  Created by 김예림 on 11/2/25.
//

import Testing
@testable import Cote
internal import Foundation

struct CoteTests {

    @Test("SearchUseCase 기본 동작 테스트")
    func testSearchUseCase() async throws {
        let useCase = await DefaultSearchUseCase()
        let results = try await useCase.execute(query: "노트 검색 코드", topK: 10)

        if results.isEmpty {
            #expect(results.isEmpty == false, "검색 결과가 비어 있음")
        }

        for r in results {
            print("🧩 \(r.title) [\(String(format: "%.2f", r.score))]")
        }
    }
}
