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
@Observable
class ChatViewModel {
    
    var messages: [ChatMessage] = []
    var userInput: String = ""
    var isResponding = false
    
    var partial: String = ""
    
    private var session: LanguageModelSession
    private let instructions = "You are a code Assistant. Your job is to give helpful explaining to coder"
    
    init() {
        self.session = LanguageModelSession(instructions: instructions)
    }
    
    func sendMessage() {
        Task {
            do {
                let stream = session.streamResponse(to: userInput)
                for try await partial in stream {
                    self.partial = partial.content
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
