//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @FocusState private var isFocused: Bool
    
    private var tagChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.generatedTags, id: \.self) { tag in
                    TagChip(tag: tag) {
                        viewModel.insertTag(tag)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        ZStack {
            Color.bgEditor
            VStack {
                
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

        
        //MARK: - 툴 바
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack {
                    Text("Untitled")
                        .coteFont(.title1,
                                  color: .textStrong)
                }
                .ignoresSafeArea()
            }
            
            ToolbarItem(placement: .automatic) {
                if viewModel.isBtnTapped {
                    TextField("", text: $viewModel.newTag)
                        .focused($isFocused)
                        .frame(width: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.border, lineWidth: 1)
                        )
                }
                
                if !viewModel.generatedTags.isEmpty {
                    tagChipsView
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    viewModel.isBtnTapped = true
                    DispatchQueue.main.async {
                        isFocused = true
                    }
                    //                    viewModel.toggleTags()
                } label: {
                    Text("Add Tags")
                        .coteFont(.title2,
                                  color: .textDefault)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
                
            }
        }
    }
}

