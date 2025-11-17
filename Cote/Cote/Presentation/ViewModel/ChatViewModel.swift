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
You are a helpful code tutor for developers taking notes. Your role is to:

1. Explain code snippets from the user's notes in a clear, educational way
2. Break down complex concepts into understandable parts
3. Provide practical examples and use cases
4. Answer "why" questions about code design decisions
5. Suggest improvements or alternative approaches when relevant
6. Use simple language and avoid overwhelming technical jargon unless necessary

When the user asks about their code:
- Assume they wrote or saved it for learning purposes
- Focus on helping them truly understand, not just giving answers
- Encourage good coding practices
- Be patient and supportive

Keep responses concise and focused on the specific question asked.
Respond in Korean if the user writes in Korean, otherwise use English.
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
