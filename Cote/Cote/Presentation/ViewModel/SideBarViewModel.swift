//
//  SideBarViewModel.swift
//  Cote
//
//  Created by 김예림 on 10/7/25.
//

import Foundation

// 노트를 선택하는 케이스만 존재함
@MainActor
final class SideBarViewModel: ObservableObject {
    private let createNoteUseCase: CreateNoteUseCase
    
    private let repo: NoteRepository
    
    @Published var roots: [NoteItems] = []
    @Published var selectedNoteID: UUID? = nil
    
    private var itemsTask: Task<Void, Never>?   // 리스트 업데이트
    private var noteTask: Task<Void, Never>?    // 노트 업데이트
    
    init(
        createNoteUseCase: CreateNoteUseCase,
        repo: NoteRepository,
        state: UIState? = nil
    ) {
        self.createNoteUseCase = createNoteUseCase
        self.repo = repo
        observeItems()
        if let s = state { selectedNoteID = s.selectedNoteID }
    }
    
    convenience init() {
        let repo = RealmNoteRepository()
        self.init(
            createNoteUseCase: DefaultCreateNoteUseCase(repository: repo),
            repo: repo,
            state: nil
        )
    }
    
    deinit {
        itemsTask?.cancel()
        noteTask?.cancel()
    }
    
    // MARK: - Stream
    private func observeItems() {
        itemsTask?.cancel()
        itemsTask = Task { [weak self] in
            guard let self else { return }
            for await items in repo.itemStream() {
                self.roots = items
            }
        }
    }
    
    func select(_ id: UUID) {
        print("select id =", id)
        noteTask?.cancel()
        noteTask = Task { [weak self] in
            guard let self else { return }
            for await _ in repo.noteStream(id: id) {
            }
        }
    }
    
    func containsNote(id: UUID) -> Bool {
        func dfs(_ item: NoteItems) -> Bool {
            switch item {
            case .note(let n): return n.id == id
            case .folder(let f):
                return f.notes.contains(where: { $0.id == id })
                || f.children.map(NoteItems.folder).contains(where: dfs)
            }
        }
        return roots.contains(where: dfs)
    }
}
