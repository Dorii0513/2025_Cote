//
//  ContentViewModel.swift
//  Cote
//
//  Created by 김예림 on 9/4/25.
//

import Foundation
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    
    @Published var content: String
    @Published var generatedTags: [String] = []
    @Published var newTag: String = ""
    @Published var isBtnTapped: Bool = false
    @Published var showTags: Bool = false
    @Published var isGenerating: Bool = false

    private let usecase: GenerateTagsUseCase

    init(initialContent: String, useCase: GenerateTagsUseCase = DefaultGenerateTagsUseCase()) {
        self.content = initialContent
        self.usecase = useCase
    }

    func toggleTags() {
        showTags.toggle()
        if showTags { Task { await generateTags() } } else { generatedTags = [] }
    }

    func insertTag(_ tag: String) {
        let insertion = "// #\(tag)\n"
        content += insertion
    }

    func generateTags() async {
        guard !isGenerating else { return }
        isGenerating = true
        defer { isGenerating = false }
        do {
            generatedTags = try await usecase.generateTags(content: content)
        } catch {
            print("[TagGeneration] failed: \(error)")
        }
    }
}
