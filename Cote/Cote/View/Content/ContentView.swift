//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var source = """
    // 여기에 코드를 작성해 보세요
    func hello() {
        print("world")
    }
    """
    @State private var tags: [String] = []
    var body: some View {
        ZStack {
            Color.bgInputDefault
            
            //dummy text
            VStack {
                CodeEditorPreviewContainer()
                HStack {
                    
                }
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack {
                    Text("Untitled")
                        .font(.title2)
                }
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    ContentView()
}
