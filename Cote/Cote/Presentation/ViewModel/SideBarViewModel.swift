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
    private let createFolderUseCase: CreateFolderUseCase
    private let repo: NoteRepositoryProtocol
    
    @Published var roots: [NoteItems] = []
    @Published var selectedNoteID: UUID? = nil
    @Published var selectedFolderID: UUID? = nil
    
    private var newNote: Note
    
    private var itemsTask: Task<Void, Never>?   // 리스트 업데이트
    private var noteTask: Task<Void, Never>?    // 노트 업데이트
    
    init(
        createNoteUseCase: CreateNoteUseCase,
        createFolderUseCase: CreateFolderUseCase,
        repo: NoteRepositoryProtocol,
    ) {
        self.createNoteUseCase = createNoteUseCase
        self.createFolderUseCase = createFolderUseCase
        self.repo = repo
        self.newNote = .init(NoteObject.init())
        observeItems()
    }
    
    convenience init() {
        let repo = NoteRepository()
        self.init(
            createNoteUseCase: DefaultCreateNoteUseCase(repository: repo), createFolderUseCase: DefaultCreateFolderUseCase(repository: repo),
            repo: repo
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
        selectedNoteID = id
        noteTask?.cancel()
        noteTask = Task { [weak self] in
            guard let self else { return }
            for await _ in repo.noteStream(id: id) {
            }
        }
    }
    
    //MARK: - Note
    
    func createNote(title: String) async{
        noteTask?.cancel()
        itemsTask?.cancel()
        
        do {
            var note = Note.init(NoteObject.init())
            note.title = title
            try await createNoteUseCase.execute(note: note)
            observeItems()
            select(note.id)
        } catch {
            print("[SideBarVM] addNewNote failed:", error.localizedDescription)
        }
        
    }
    
    func deleteNote(id: UUID) {
        noteTask?.cancel()
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repo.deleteNote(id: id)
                if self.selectedNoteID == id { self.selectedNoteID = nil }
            } catch {
                print("[SideBarVM] delete failed: \(error)")
            }
        }
    }
    
    //MARK: - Folder
    func createFolder(name: String, parentID: UUID? = nil) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let id = try await repo.createFolder(name: name, parentID: parentID)
                self.selectedFolderID = id
            } catch {
                print("[SideBarVM] createFolder failed:", error.localizedDescription)
            }
        }
    }
    
    func deleteFolder(id: UUID) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repo.deleteFolder(id: id)
                if self.selectedFolderID == id { self.selectedFolderID = nil }
            } catch {
                print("[SideBarVM] deleteFolder failed: \(error)")
            }
        }
    }
    
    // MARK: - Drag & Drop
    func moveNote(noteID: UUID, toFolder folderID: UUID) {
        noteTask?.cancel()
        noteTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await repo.moveNote(noteID: noteID, toFolderID: folderID)
                self.selectedNoteID = noteID
            } catch {
                print("[SideBarVM] moveNote failed: \(error)")
            }
        }
    }
    
    func moveNoteToRoot(noteID: UUID) {
        noteTask?.cancel()
        noteTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await repo.moveNoteToRoot(noteID: noteID)
                self.selectedNoteID = noteID
            } catch {
                print("[SideBarVM] moveNoteToRoot failed: \(error)")
            }
        }
    }
}
