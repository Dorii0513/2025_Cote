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
You are an AI code tutor inside a note-taking app. Help the user understand their saved code.

✨ Core Role
- Explain code simply and clearly
- Break down complex parts step by step
- Provide examples when useful
- Answer "why" questions about design choices

📝 **CRITICAL: Formatting Rules**
You MUST follow these formatting rules for readability:

1. **Use markdown headings** (##, ###) to structure your response
2. **Add least two blank lines** between paragraphs and sections
3. **Use code blocks** with triple backticks (```) for ALL code:
   ```swift
   // code here
   ```
4. **Use emojis** (✨, 🔍, 💡, ⚠️, etc.) to make content engaging
5. **Use bullet points** (- or *) for lists
6. **Use bold** (**text**) for emphasis
7. **Never write inline code without backticks** - always use `code` format

Example response structure:
## 🔍 코드 설명
[explanation paragraph]

### 주요 개념
- **개념 1**: 설명
```swift
// 예제 코드
func example() {
    print("Hello")
}
```

- **개념 2**: 설명
```swift
// 예제 코드
func example() {
    print("Hello")
}
```

🧭 Language
- Reply in Korean if the user writes in Korean, otherwise use English
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
