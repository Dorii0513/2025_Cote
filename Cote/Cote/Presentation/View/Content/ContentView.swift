//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI
import AppKit

//MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @EnvironmentObject private var state: UIState
    
    var body: some View {
        ZStack {
            Color.bgEditor
            VStack(alignment: .leading, spacing: 0) {
                
                Spacer().frame(height: 38)
                
                // 에디터 뷰
                CodeEditor(text: $viewModel.content)
                    .onChange(of: viewModel.content, scheduleAutosave)
                    .onChange(of: viewModel.title, scheduleAutosave)
                    .onChange(of: viewModel.noteTags, scheduleAutosave)
                    .task {
                        await viewModel.loadMostRecentNote()
                    }
                
                // Command-S 저장
                Button("") {
                    Task {
                        if let id = state.selectedNoteID {
                            await viewModel.saveCurrentNote(noteID: id)
                        }
                    }
                }
                .keyboardShortcut("s", modifiers: [.command])
                .hidden()
                
                // 하단 바
                BottomBar()
                
            }
        }
        .ignoresSafeArea()
    }
    
    private func scheduleAutosave(oldValue: Any, newValue: Any) {
        AutosaveScheduler.shared.schedule {
            Task {
                guard let id = state.selectedNoteID else { return }
                await viewModel.saveCurrentNote(noteID: id)
            }
        }
    }
}

//MARK: - BottomBar
private struct BottomBar: View {
    var body: some View {
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

//MARK: - AutosaveScheduler
fileprivate final class AutosaveScheduler {
    static let shared = AutosaveScheduler()
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval = 0.8
    
    func schedule(_ action: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
}
