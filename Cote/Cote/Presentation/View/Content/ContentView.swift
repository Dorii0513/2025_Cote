//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI
import AppKit

//private struct TagFieldAnchorKey: PreferenceKey {
//    static var defaultValue: Anchor<CGRect>? = nil
//    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
//        value = nextValue() ?? value
//    }
//}

struct ContentView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
//    @State private var isBtnTapped: Bool = false
    
    var body: some View {
        ZStack {
            Color.bgEditor
            VStack(alignment: .leading, spacing: 0) {
//                Cote.contentToolbar(isBtnTapped: $isBtnTapped)
//                    .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
//                    .background(.bgSidebar)
                
                Spacer().frame(height: 38)
                
                // 에디터 뷰
                //TextEditor(text: $viewModel.content)
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
    }
}

