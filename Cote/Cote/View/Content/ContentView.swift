//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI

//TODO: - 리팩토링 필요 ( 뷰 분리해야 함. 하단 바, 태그 칩스 ...)

struct ContentView: View {
    @State private var tags: [String] = []
    @State private var showTags: Bool = false
    @State private var isGeneratingTags: Bool = false
    private let tagGenerator = TagGenerator()
    @State private var content: String = """
import PDFKit

class PDFAnnotationHandler {
    private var pdfView: PDFView
    
    init(view: PDFView) {
        self.pdfView = view
    }
    
    func addUnderline(to selection: PDFSelection) {
        let underline = PDFAnnotation(bounds: selection.bounds(for: pdfView.currentPage!),
                                      forType: .underline,
                                      withProperties: nil)
        pdfView.currentPage?.addAnnotation(underline)
    }
}
"""
    
    private func toggleTags() {
        showTags.toggle()
        if showTags {
            generateTags()
        } else {
            tags = []
        }
    }
    
    private func generateTags() {
        guard !isGeneratingTags else { return }
        
        isGeneratingTags = true
        
        Task {
            do {
                let generatedTags = try await tagGenerator.generateTags(for: content)
                await MainActor.run {
                    self.tags = generatedTags
                    self.isGeneratingTags = false
                }
            } catch {
                await MainActor.run {
                    print("Failed to generate tags: \(error)")
                    self.isGeneratingTags = false
                }
            }
        }
    }
    
    private func insertTag(_ tag: String) {
        let insertion = "// #\(tag)\n"
        content += insertion
    }
    
    private var tagChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(tag: tag) {
                        insertTag(tag)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        ZStack {
            Color.bgInputDefault
            VStack {
                // 에디터 뷰
                CodeEditorPreviewContainer()
                
                // 하단 바
                HStack {
                    HStack(spacing: 15) {
                        Text("2025/05/27")
                        Text("3:40pm")
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 15) {
                        HStack(spacing: 4) {
                            Text("Line")
                                .foregroundStyle(.textLabelInfo)
                            Text("123")
                        }
                        
                        HStack(spacing: 4) {
                            Text("Col")
                                .foregroundStyle(.textLabelInfo)
                            Text("299")
                        }
                        
                        Button {
                            
                        } label: {
                            HStack(spacing: 4) {
                                Image("language")
                                Text("Swift")
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .coteFont(.code2, color: .textLabelDefault)
                .padding(.horizontal, 15)
                .padding(.vertical, 2)
                .background(.bgInputDefault)
            }
        }
        
        //TODO: - 툴바에 태그 칩스 만들어야 함. codeEditor 뷰에서 가져오기
        
        //MARK: - 툴 바
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack {
                    Text("Untitled")
                        .coteFont(.title1,
                                  color: .textDefault)
                }
                .ignoresSafeArea()
            }
            
            // tag chips
            ToolbarItem(placement: .automatic) {
                if !tags.isEmpty {
                    tagChipsView
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    toggleTags()
                } label: {
                    Text("Add Tags")
                        .coteFont(.title2,
                                  color: .textTagDefault)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
                
            }
        }
    }
}

// MARK: - Tag Chip View
private struct TagChip: View {
    let tag: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



#Preview {
    ContentView()
}
