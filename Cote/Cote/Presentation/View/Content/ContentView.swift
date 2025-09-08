//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI
import AppKit

private struct TagFieldAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @State private var isBtnTapped: Bool = false
    
    var body: some View {
        ZStack {
            Color.bgEditor
            VStack(alignment: .leading, spacing: 0) {
                contentToolbar(isBtnTapped: $isBtnTapped)
                    .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
                    .background(.bgSidebar)
                
                // 에디터 뷰
                CodeEditor(text: $viewModel.content, suggestedTags: $viewModel.generatedTags, showSuggestedTags: $viewModel.showTags)
                
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
                                .foregroundStyle(.textInfo)
                            Text("123")
                        }
                        
                        HStack(spacing: 4) {
                            Text("Col")
                                .foregroundStyle(.textInfo)
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
                .coteFont(.code2, color: .textDefault)
                .padding(.horizontal, 15)
                .padding(.vertical, 2)
                .background(.bgEditor)
            }
        }
        .ignoresSafeArea()
        .overlayPreferenceValue(TagFieldAnchorKey.self) { anchor in
            GeometryReader { proxy in
                if isBtnTapped, let anchor {
                    let rect = proxy[anchor]
                    TagSuggestionsView()
                        .frame(maxWidth: 500, alignment: .leading)
                        .position(x: rect.minX + 250,
                                  y: rect.maxY + 60)
                }
            }
        }
    }
}

private struct contentToolbar: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @FocusState private var isFocused: Bool
    @State private var newTag: String = ""
    @Binding var isBtnTapped: Bool
    
    private var tagChipsView: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.noteTags, id: \.self) { tag in
                TagChip(tag: tag){}
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Untitled")
                .coteFont(.title1,
                          color: .textStrong)
                .padding(.trailing, 8)
            
            if !viewModel.noteTags.isEmpty {
                tagChipsView
                    .padding(.trailing, 8)
            }
            
            if isBtnTapped {
                TextField("", text: $newTag)
                    .focused($isFocused)
                    .tint(.textDefault)
                    .coteFont(.tag, color: .textDefault)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .frame(minWidth: 60, alignment: .leading)
                    .fixedSize()
                    .textFieldStyle(.plain)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .anchorPreference(key: TagFieldAnchorKey.self,
                                                  value: .bounds) { $0 }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.border, lineWidth: isFocused ? 2 : 1)
                    )
                    .onSubmit(of: .text) {
                        withAnimation(.smooth) {
                            viewModel.addNewTag(newTag)
                            newTag = ""
                        }
                    }
                    .onChange(of: isFocused, initial: false) { oldValue, newValue in
                        if !newValue && newTag.isEmpty {
                            withAnimation(.snappy) {
                                isBtnTapped = false
                            }
                        }
                    }
            }
            
            if !isBtnTapped {
                Button {
                    isBtnTapped = true
                    isFocused = true
                    viewModel.toggleTags()
                } label: {
                    Text("Add Tags")
                        .coteFont(.title2,
                                  color: .textDefault)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 15)
    }
}

