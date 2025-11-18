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
    @StateObject private var state = UIState()
    @FocusState private var isFocused: Bool
    
    @State private var showNote: Bool = false
    @State private var isHover: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            if viewModel.messages.isEmpty {
                EmptyView
            } else {
                
                HStack {
                    Spacer()
                    Button {
                        viewModel.reset()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.trianglehead.clockwise")
                                .font(.system(size: 10))
                                .foregroundStyle(.iconSecondary)
                            Text("Reset")
                                .coteFont(.text3, color: .iconSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                MessageView
            }
            //RecommendView
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
        .onChange(of: state.selectedNoteID) {
            if let id = state.selectedNoteID {
                Task { @MainActor in
                    await viewModel.fetchFocusNote(id: id)
                }
            }
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
    private var FocusNoteView: some View {
        
        HStack(spacing: 10) {
            
            CustomChipLayout(spacing: 10) {
                if !viewModel.focusedNotes.isEmpty {
                    ForEach(viewModel.focusedNotes) { note in
                        NoteChip(selectedNote: note,
                                 mode: .label,
                                 onSelect: {
                            withAnimation(.easeInOut(duration: 0.2) ){
                                viewModel.deleteFocusedNote(id: note.id)
                            }
                        })
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                if !viewModel.focusedNotes.contains(where: { $0.id == state.selectedNoteID }) {
                    NoteChip(selectedNote: viewModel.selectedNote,
                             mode: .button,
                             onSelect: {
                        withAnimation(.easeInOut(duration: 0.2 )) {
                            viewModel.addFocusedNotes()
                        }
                    })
                    .transition(.opacity.combined(with: .scale))
                }
            }
            Spacer()
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
        VStack {
            if showNote {
                FocusNoteView
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            }
            HStack {
                
                Button {
                    if let id = state.selectedNoteID {
                        Task { @MainActor in
                            await viewModel.fetchFocusNote(id: id)
                            withAnimation(.easeInOut) {
                                showNote.toggle()
                            }
                        }
                    }
                } label: {
                    Image(systemName: "eye")
                        .foregroundStyle(showNote ? .aiDefault : .iconSecondary)
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill( isHover ? .actionDefault : .clear)
                        )
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
                .onHover(perform: { hovering in
                    isHover = hovering
                })
                //            .tooltip("Preview note focus mode.")
                
                TextField("Write a question here...", text: $viewModel.userInput)
                    .focused($isFocused, equals: true)
                    .coteFont(.text2, color: .textSelected)
                    .tint(.textDefault)
                    .textFieldStyle(.plain)
                    .padding(.leading, 4)
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

