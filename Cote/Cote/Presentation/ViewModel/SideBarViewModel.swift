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


    @Published var roots: [NoteItems] = [
        .folder(Folder(name: "Folder1", sortIndex: 0, updatedAt: Date(), notes: [Note(id: UUID(), title: "Untitled1", content: "...")], children: []))
    ]
    @Published var selectedNoteID: UUID? = nil  // 로컬 보관(뷰에서 바인딩하기 쉬움)
    
    private weak var state: UIState?
    private var treeTask: Task<Void, Never>?

    init(
        createNoteUseCase: CreateNoteUseCase,
        repo: NoteRepository,
        state: UIState? = nil
    ) {
        self.createNoteUseCase = createNoteUseCase
        self.repo = repo
        self.state = state
        observeTree()
    }

    convenience init() {
        let repo = RealmNoteRepository()
        self.init(
            createNoteUseCase: DefaultCreateNoteUseCase(repository: repo),
            repo: repo,
            state: nil
        )
    }

    deinit { treeTask?.cancel() }
    
    func attach(_ state: UIState) {
        self.state = state
        self.selectedNoteID = state.selectedNoteID
    }

    // MARK: - Stream
    private func observeTree() {
        treeTask = Task {
            for await folders in repo.treeStream() {
                // Folder[] → NoteItems[] (폴더 먼저, 정렬 규칙 일관 적용)
                self.roots = folders.map(NoteItems.folder).sortNotes()
            }
        }
    }

    // MARK: - Selection
//    func select(_ item: NoteItems) {
//        switch item {
//        case .note(let n):
//            selectedNoteID = n.id
//            state?.selectedNoteID = n.id
//        case .folder:
//            // 폴더는 토글만 담당
//            toggle(item)
//        }
//    }

    private func bindSelectionToAppState() {
        // 선택이 외부(AppState)에서 바뀌면 반영 (양방향 동기화가 필요할 때)
        guard let app = state else { return }
        // 간단히 값 동기화(지속 구독이 필요하면 Combine으로 sink 추가)
        selectedNoteID = app.selectedNoteID
    }

    // MARK: - Create
    /// 폴더 ID 지정 없으면 루트(또는 인박스) 정책에 맞춰 repo가 처리
    func addNote(inFolderID folderID: String? = nil, title: String = "새 노트")
        async
    {
        let note = Note(
            id: UUID(),
            title: title,
            content: "",
            tags: [],
            updatedAt: .now
        )
        do {
            try await createNoteUseCase.execute(note: note)
            // 생성 직후 해당 노트로 포커스 이동
            selectedNoteID = note.id
            state?.selectedNoteID = note.id
        } catch {
            print("[SideBar] addNote failed:", error)
        }
    }

    // MARK: - Helpers
    private func containsNote(id: UUID) -> Bool {
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

    //    func reload() {
    //        Task { @MainActor in
    //            do {
    //                let notes = try await fetchNotesUseCase.execute()
    //                self.roots = notes.map(NoteItems.note).sortedForUI()
    //            } catch {
    //                print("Failed to load notes: \(error)")
    //            }
    //        }
    //    }
    //
    //    func addNote() {
    //        Task { @MainActor in
    //            do {
    //                let new = Note(id: UUID(), title: "Untitled", content: "", tags: [])
    //                _ = try await createNoteUseCase.execute(note: new)
    //                reload()
    //            } catch {
    //                print("Failed to create note: \(error)")
    //            }
    //        }
    //    }
}
