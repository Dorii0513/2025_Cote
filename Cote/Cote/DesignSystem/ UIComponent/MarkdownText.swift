//
//  MarkdownText.swift
//  Cote
//
//  Created by 김예림 on 11/17/25.
//

import SwiftUI

struct MarkdownText: View {
    let markdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks(from: markdown).enumerated()), id: \.offset) { _, block in
                render(block: block)
            }
        }
    }

    @ViewBuilder
    func render(block: MarkdownBlock) -> some View {
        switch block {
        case .code(let code, let language):
            CodeBlockView(code: code, language: language)
        case .text(let lines):
            ForEach(lines, id: \.self) { line in
                render(line: line)
            }
        }
    }
    
    @ViewBuilder
    func render(line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // 0. 테이블 행 처리: 파이프로 시작하는 줄
        if trimmed.hasPrefix("|") {
            // | ... | 형태에서 양 끝 파이프 포함한 상태
            let rawCells = trimmed.split(separator: "|", omittingEmptySubsequences: false)
            
            // 보통 맨 앞/뒤는 빈 셀이라 버림
            let cellStrings = rawCells
                .dropFirst()
                .dropLast()
                .map { String($0).trimmingCharacters(in: .whitespaces) }
            
            // 구분선(---, :---:, 등)만 있는 줄이면 스킵
            let dashSet = CharacterSet(charactersIn: "-: ")
            let isSeparatorRow = cellStrings.allSatisfy { cell in
                cell.unicodeScalars.allSatisfy { dashSet.contains($0) }
            }
            
            if isSeparatorRow {
                EmptyView()
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(cellStrings.enumerated()), id: \.offset) { _, cell in
                        Text(try! AttributedString(markdown: cell))
                            .coteFont(.text1, color: .textDefault)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
            
        // 1. 헤더
        } else if trimmed.hasPrefix("### ") {
            Text(String(trimmed.dropFirst(4)))
                .coteFont(.markS, color: .textDefault)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
        } else if trimmed.hasPrefix("## ") {
            Text(String(trimmed.dropFirst(3)))
                .coteFont(.markM, color: .textDefault)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
        } else if trimmed.hasPrefix("# ") {
            Text(String(trimmed.dropFirst(2)))
                .coteFont(.markL, color: .textDefault)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
        // 2. 리스트(-, *)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            let content = String(trimmed.dropFirst(2))
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .coteFont(.mark, color: .textDefault)
                Text(try! AttributedString(markdown: content))
                    .coteFont(.mark, color: .textDefault)
            }
            
        // 3. 일반 텍스트
        } else if !trimmed.isEmpty {
            Text(try! AttributedString(markdown: trimmed))
                .coteFont(.mark, color: .textDefault)
        }
    }

    func parseBlocks(from markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var currentTextLines: [String] = []
        var inCodeBlock = false
        var codeLines: [String] = []
        var codeLanguage: String? = nil
        
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        
        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // 코드 블록 종료
                    if !codeLines.isEmpty {
                        blocks.append(.code(code: codeLines.joined(separator: "\n"), language: codeLanguage))
                    }
                    codeLines = []
                    codeLanguage = nil
                    inCodeBlock = false
                } else {
                    // 코드 블록 시작
                    if !currentTextLines.isEmpty {
                        blocks.append(.text(lines: currentTextLines))
                        currentTextLines = []
                    }
                    inCodeBlock = true
                    let language = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    codeLanguage = language.isEmpty ? nil : language
                }
            } else if inCodeBlock {
                codeLines.append(line)
            } else {
                currentTextLines.append(line)
            }
        }
        
        // 남은 텍스트 추가
        if !currentTextLines.isEmpty {
            blocks.append(.text(lines: currentTextLines))
        }
        
        // 닫히지 않은 코드 블록 처리
        if !codeLines.isEmpty {
            blocks.append(.code(code: codeLines.joined(separator: "\n"), language: codeLanguage))
        }
        
        return blocks
    }
}

enum MarkdownBlock {
    case text(lines: [String])
    case code(code: String, language: String?)
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더
            HStack {
                if let language = language {
                    Text(language)
                        .coteFont(.text3, color: .textDefault)
                        .opacity(0.7)
                }
                
                Spacer()
                
                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(.textDefault)
                        Text(isCopied ? "Copied" : "Copy")
                            .coteFont(.text3, color: .textDefault)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.15))
            
            // 코드 내용
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.textDefault)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.05))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}
