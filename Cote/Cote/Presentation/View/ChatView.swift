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
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer().frame(height: 20)
            
            if viewModel.messages.isEmpty {
                EmptyView
            } else {
                MessageView
            }
            RecommendView
            TextFieldView
        }
        .padding(.top, 20)
        .padding(.horizontal, 15)
        .onAppear() {
            isFocused = true
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
    }
    
    @ViewBuilder
    private var EmptyView: some View {
        Spacer()
        HStack(alignment: .center) {
            Text("New Conversation with Cote")
                .coteFont(.text1, color: .textDefault)
        }
        .frame(maxWidth: .infinity)
        Spacer()
    }
    
    @ViewBuilder
    private var MessageView: some View {
        ScrollViewReader { proxy in
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
                }
                .padding(.horizontal, 10)
                // 아래로 자동 스크롤
                .onChange(of: viewModel.partial) { _, _ in
                    if let id = viewModel.partialId {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var RecommendView: some View {
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
    }
    
    @ViewBuilder
    private var TextFieldView: some View {
        HStack {
            TextField("Write a question here...", text: $viewModel.userInput)
                .focused($isFocused, equals: true)
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
                    .foregroundStyle(viewModel.userInput.isEmpty ? .clear : .aiDefault)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .scale))
        }
        .padding([.vertical, .horizontal], 5)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.bgTextField)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isFocused ? .aiSecondary.opacity(0.7) : .aiMuted, lineWidth: 2)
                        .shadow(color: .aiSecondary, radius: 5)
                )
        )
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.2), value: viewModel.userInput.isEmpty)
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
            .lineSpacing(8)
            .padding(.horizontal, sender == .user ? 12 : 0)
            .padding(.vertical, 8)
            .background(sender == .user ? .actionDefault : Color.clear)
            .cornerRadius(20)
            .padding(sender == .user ? .leading : .trailing, 20)
            .frame(maxWidth: .infinity,
                   alignment: sender == .user ? .trailing : .leading)
    }
}
