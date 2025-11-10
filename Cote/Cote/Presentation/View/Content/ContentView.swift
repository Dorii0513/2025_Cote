//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI
import AppKit
import RealmSwift
import Highlightr

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
                CodeEditor(text: $viewModel.content,
                           language: $viewModel.language)
                    .id(viewModel.currentNoteID)
                    .onChange(of: viewModel.content, scheduleAutosave)
                    .onChange(of: viewModel.title, scheduleAutosave)
                    .onChange(of: viewModel.noteTags, scheduleAutosave)
                    .onChange(of: viewModel.language, scheduleAutosave)
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
        }
        .ignoresSafeArea()
        .frame(minWidth: 540)
    }
    
    private func clearEditor() {
        viewModel.title = ""
        viewModel.content = ""
        viewModel.noteTags = []
        viewModel.language = "plainText"
    }
    
    private func scheduleAutosave(oldValue: Any, newValue: Any) {
        guard !viewModel.isLoading else { return }
        AutosaveScheduler.shared.schedule {
            guard !viewModel.isLoading else {
                return
            }
            
            Task { @MainActor in
                if let id = viewModel.currentNoteID {
                    await viewModel.saveCurrentNote(by: id)
                }
            }
        }
    }
}

//MARK: - BottomBar
private struct BottomBar: View {
    let date: Date?
    let highlightr = Highlightr()!
    @Binding var language: String
    let onSelect: (String) -> Void
    
    @State private var isHover: Bool = false

    var body: some View {
        let languages = highlightr.supportedLanguages()
        
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
//                HStack(spacing: 4) {
//                    Text("Line")
//                        .foregroundStyle(.textInfo)
//                    Text("123")
//                }
//                
//                HStack(spacing: 4) {
//                    Text("Col")
//                        .foregroundStyle(.textInfo)
//                    Text("299")
//                }
                
                // language 선택
                Menu {
                    ForEach(languages, id: \.self) { select in
                        Button {
                            onSelect(select)
                        } label: {
                            HStack {
                                Text(select)
                                if select == language {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .frame(height: 100)
                } label: {
                    HStack(spacing: 4) {
                        Image("language")
                        Text(language)
                            .coteFont(.code2, color: .textMuted)
                    }
                }
                .menuStyle(.borderlessButton)
                .tint(isHover ? .textDefault : .textMuted)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.actionDefault)
                        .opacity(isHover ? 1.0 : 0)
                )
                .onHover(perform: { hover in
                    isHover = hover
                })
            }
        }
        .coteFont(.code2, color: .textMuted)
        .padding(.leading, 15)
        .padding([.vertical, .trailing], 8)
        .background(.bgEditor)
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
