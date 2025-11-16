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
final class ChatViewModel: ObservableObject {
    
    @Published var messages: [ChatMessage] = []
    @Published var userInput: String = ""
    @Published var isResponding = false
    
    @Published var partial: String?
    @Published var partialId: UUID?
    
    private var session: LanguageModelSession
    private let instructions = "You are a code Assistant. Your job is to give helpful explaining to coder"
    private var streamingTask: Task<Void, Never>?
    
    init() {
        self.session = LanguageModelSession(instructions: instructions)
    }
    
    func sendMessage() {
        
        messages.append(ChatMessage(sender: .user, content: userInput))
        
        Task {
            do {
                let stream = session.streamResponse(to: userInput)
                partialId = UUID()
                
                for try await partial in stream {
                    self.partial = partial.content
                    
                    print(partial)
                }
                
                guard !Task.isCancelled else { return }
                
                if let finalContent = partial {
                    await MainActor.run {
                        messages.append(ChatMessage(sender: .assistant, content: finalContent))
                        partial = nil
                        partialId = nil
                        isResponding = false
                    }
                }
                
            } catch {
                print("error: \(error)")
                if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
                    print("error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func reset() {
        messages = []
        userInput = ""
        isResponding = false
    }
    
}
