//
//  ChatView.swift
//  Cote
//
//  Created by 김예림 on 11/16/25.
//

import SwiftUI
import FoundationModels

@available(macOS 26.0, *)
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach (viewModel.messages) { message in
                        MarkdownText(markdown: message.content)
                            .modifier(StreamingViewModifier(sender: message.sender))
                    }
                    
                    if let partial = viewModel.partial, let id = viewModel.partialId {
                        StreamingResponseView(partial: partial)
                            .id(id)
                    } else if viewModel.isResponding {
                        ProgressView()
                    }
                    
                    Text(viewModel.partial ?? "")
                }
            }
            
            HStack {
                Button {

                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles.2")
                            .foregroundStyle(.iconDefault)
                        Text("Generate Comments")
                            .coteFont(.text2, color: .textDefault)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.actionDefault)
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles.2")
                            .foregroundStyle(.iconDefault)
                        Text("Generate Tags")
                            .coteFont(.text2, color: .textDefault)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.actionDefault)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            
            HStack {
                TextField("Write a question here...", text: $viewModel.userInput)
                    .coteFont(.text2, color: .textSelected)
                    .tint(.textDefault)
                    .textFieldStyle(.plain)
                    .padding(.leading, 6)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Spacer()
                
                Button {
                    viewModel.sendMessage()
                } label: {
                    Image("arrow_up")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.textTag)
                        
//                        .padding(3)
                }
                .buttonStyle(.plain)
            }
            .padding([.vertical, .horizontal], 5)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.bgTextField)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.textTag.opacity(0.5), lineWidth: 2)
                            .shadow(color: .textTag, radius: 5)
                    )
            )
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 15)
    }
}

struct StreamingResponseView: View {
    
    let partial: String
    
    var body: some View {
        MarkdownText(markdown: partial)
            .modifier(StreamingViewModifier(sender: .assistant))
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.7), value: partial)
    }
}

struct StreamingViewModifier: ViewModifier {
    
    let sender: ChatMessage.Sender
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(sender == .user ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3))
            .cornerRadius(12)
            .padding(sender == .user ? .leading : .trailing, 20)
            .frame(maxWidth: .infinity,
                   alignment: sender == .user ? .trailing : .leading)
    }
}

//#Preview {
//    ChatView(message: "zz")
//}

