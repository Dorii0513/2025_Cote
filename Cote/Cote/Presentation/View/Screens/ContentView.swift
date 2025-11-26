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
        ZStack(alignment: .bottom) {
            Color.bgEditor
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 38)
                
                // 에디터 뷰
                CodeEditor(text: $viewModel.content,
                           language: $viewModel.language, 
                           aiComments: $viewModel.aiComments)
                    .id(viewModel.currentNoteID)
                    .onChange(of: viewModel.title) { _,newValue in
                        scheduleAutosave(field: .title(newValue))
                    }
                    .onChange(of: viewModel.content) { _,newValue  in
                        scheduleAutosave(field: .content(newValue))
                    }
                    .onChange(of: viewModel.noteTags) { _,newValue  in
                        scheduleAutosave(field: .tags(newValue))
                    }
                    .onChange(of: viewModel.language) { _,newValue  in
                        scheduleAutosave(field: .language(newValue))
                    }
                    .onChange(of: state.selectedNoteID) { _, newID in
                        guard let id = newID else { return }
                        _ = try! Realm()
                        Task { await viewModel.loadNote(by: id) }
                    }
                    .task {
                        if let id = state.selectedNoteID { await viewModel.loadNote(by: id) }
                    }
                
                // 하단 바
                BottomBar(date: viewModel.updatedAt ?? nil, language: $viewModel.language){ select in
                    viewModel.language = select
                }
            }
            
            if viewModel.showUndoButton {
                UndoCommentsButton
                    .padding(.bottom, 60)
                    .transition(
                        .move(edge: .bottom).combined(with: .opacity)
                    )
            }
        }
        .ignoresSafeArea()
        .frame(minWidth: 400)
        .animation(.smooth(duration: 0.3), value: viewModel.showUndoButton)
    }
    
    @ViewBuilder
    private var UndoCommentsButton: some View {
        Button {
            viewModel.undoComments()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12))
                    .foregroundStyle(.textSelected)
                Text("Undo Comment")
                    .coteFont(.text2, color: .textSelected)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black200 , radius: 9)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func clearEditor() {
        viewModel.title = ""
        viewModel.content = ""
        viewModel.noteTags = []
        viewModel.language = "plainText"
    }
    
    private func scheduleAutosave(field: NoteSaveField) {
        guard !viewModel.isLoading else { return }
        AutosaveScheduler.shared.schedule {
            
            guard !viewModel.isLoading else { return }
            
            Task { @MainActor in
                if let id = viewModel.currentNoteID {
                    await viewModel.updateNote(by: id, save: field)
                }
            }
        }
    }
}

//MARK: - AutosaveScheduler
fileprivate final class AutosaveScheduler {
    static let shared = AutosaveScheduler()
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval = 1.0
    
    func schedule(_ action: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
}
