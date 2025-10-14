//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI
import AppKit
import RealmSwift

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
                    .id(viewModel.currentNoteID)
                    .onChange(of: viewModel.content, scheduleAutosave)
                    .onChange(of: viewModel.title, scheduleAutosave)
                    .onChange(of: viewModel.noteTags, scheduleAutosave)
                    .onChange(of: state.selectedNoteID) { _, newID in
                        guard let id = newID else { return }
                        let r = try! Realm()
                        Task { await viewModel.loadNote(by: id) }
                    }
                    .task {
                        if let id = state.selectedNoteID { await viewModel.loadNote(by: id) }
                    }
                
                // 하단 바
                BottomBar(date: viewModel.updatedAt ?? nil)
                
            }
        }
        .ignoresSafeArea()
        .frame(minWidth: 540)
    }
    
    private func clearEditor() {
        viewModel.title = "Untitled"
        viewModel.content = ""
        viewModel.noteTags = []
    }
    
    private func scheduleAutosave(oldValue: Any, newValue: Any) {
        // 로딩 중엔 autosave 금지
        guard !viewModel.isLoading else { return }
        AutosaveScheduler.shared.schedule {
            Task { if let id = state.selectedNoteID { await viewModel.saveCurrentNote(by: id) } }
        }
    }
}

//MARK: - BottomBar
private struct BottomBar: View {
    let date: Date?
    var body: some View {
        HStack {
            HStack(spacing: 15) {
                if let date {
                    Text(date, style: .date)
                    Text(date, style: .time)
                } else {
                    Text("")
                }
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
        .coteFont(.code2, color: .textSecondary)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
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
