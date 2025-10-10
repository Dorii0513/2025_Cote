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
//        selectedNoteID = id
        print("select id =", id)
        noteTask?.cancel()
        noteTask = Task { [weak self] in
            guard let self else { return }
            for await _ in repo.noteStream(id: id) {
                // 콘텐츠 뷰 바인딩을 다른 ViewModel로 전달하거나, AppState를 통해 반영
                // 현재 우선순위 목적에서는 id 전달만으로 충분하므로 비워둠
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
    
    
//    private func bindSelectionToAppState() {
//        // 선택이 외부(AppState)에서 바뀌면 반영 (양방향 동기화가 필요할 때)
//        guard let app = state else { return }
//        // 간단히 값 동기화(지속 구독이 필요하면 Combine으로 sink 추가)
//        selectedNoteID = app.selectedNoteID
//    }
    
    // MARK: - Create
//    func addNote(inFolderID folderID: String? = nil, title: String = "새 노트")
//    async
//    {
//        let note = Note(
//            id: UUID(),
//            title: title,
//            content: "",
//            tags: [],
//            updatedAt: .now
//        )
//        do {
//            try await createNoteUseCase.execute(note: note)
//            // 생성 직후 해당 노트로 포커스 이동
//            selectedNoteID = note.id
//            state?.selectedNoteID = note.id
//        } catch {
//            print("[SideBar] addNote failed:", error)
//        }
//    }
}
