//
//  ChatViewModel.swift
//  Cote
//
//  Created by 김예림 on 11/16/25.
//

import Foundation
import FoundationModels
import SwiftUI

@available(macOS 26.0, *)
@MainActor
final class ChatViewModel: ObservableObject {
    
    private let fetchUseCase: FetchNotesUseCase
    
    @Published var messages: [ChatMessage] = []
    @Published var userInput: String = ""
    @Published var isResponding = false
    
    @Published var selectedNote: FocusedNote?
    @Published var focusedNotes: [FocusedNote] = []
    
    @Published var partial: String?
    @Published var partialId: UUID?
    
    private var session: LanguageModelSession
    private static let instructions = """
    너는 사용자의 질문에 대해 답변해주는 채팅 어시스턴트야.
    사용자가 물어보는 질문에만 집중해서 깔끔하고 정확하게 markdown 형식으로 답변해줘.
    또한 좋은 가독성을 위해 내용에 맞는 이모지를 사용해줘 
    그리고 헤더처리(#,##,###)를 사용해줘 
    필요에 따라 표 형태를 사용해줘
    그리고 집중해야 하는 코드 부분에만 코드 블럭을 적극적으로 활용해줘.
    """
    private var streamingTask: Task<Void, Never>?
    
    init(
        fetchUseCase: FetchNotesUseCase,
        session: LanguageModelSession
    ) {
        self.fetchUseCase = fetchUseCase
        self.session = session
    }
    
    convenience init() {
        self.init(
            fetchUseCase: DefaultFetchNotesUseCase(),
            session: LanguageModelSession(instructions: ChatViewModel.instructions)
        )
    }
    
    func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        let inputText = userInput
        let newMessage = ChatMessage(sender: .user, content: inputText)
        messages.append(newMessage)
        userInput = ""
        
        var fullPrompt = inputText
        if !focusedNotes.isEmpty {
            let noteContext = focusedNotes.map { note in
                    """
                    ### \(note.title)
                    \(note.content)
                    """
            }.joined(separator: "\n\n---\n\n")
            
            fullPrompt = """
                [참고할 코드]
                \(noteContext)
                
                [사용자 질문]
                \(inputText)
                """
        }
        
        Task {
            do {
                isResponding = true
                partialId = UUID()
                partial = ""
                
                let stream = session.streamResponse(to: fullPrompt)
                
                for try await partial in stream {
                    self.partial = partial.content
                    
                    print(partial)
                }
                
                if let finalContent = partial {
                    messages.append(ChatMessage(sender: .assistant, content: finalContent))
                    partial = nil
                    partialId = nil
                }
                isResponding = false
                
            } catch {
                isResponding = false
                partial = nil
                partialId = nil
                print("error: \(error)")
                if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
                    print("error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchFocusNote(id: UUID) async {
        do {
            if let note = try await fetchUseCase.execute(noteID: id) {
                selectedNote = FocusedNote(
                    id: note.id,
                    title: note.title,
                    content: note.content
                )
            }
        } catch {
            print("fetchFocusNote error =", error)
        }
        
    }
    
    func addFocusedNotes() {
        if let note = selectedNote {
            if !focusedNotes.contains(where: { $0.id == note.id }) {
                focusedNotes.append(note)
            }
        }
    }
    
    func deleteFocusedNote(id: UUID) {
        focusedNotes.removeAll { $0.id == id }
    }
    
    func reset() {
        messages = []
        userInput = ""
        isResponding = false
    }
}

struct FocusedNote: Identifiable {
    let id: UUID
    let title: String
    let content: String
}
