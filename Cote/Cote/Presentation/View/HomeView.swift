//
//  HomeView.swift
//  Cote
//
//  Created by 김예림 on 7/26/25.
//

import SwiftUI
import AppKit

struct HomeView: View {
    @State private var sidebarWidth: CGFloat = 210
    @State private var chatViewWidth: CGFloat = 250
    
    @State private var isBtnTapped: Bool = false
    @State private var showEdge_L: Bool = false
    @State private var showEdge_R: Bool = false
    @State private var showChat: Bool = false
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var state = UIState()
    
    var body: some View {
        
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                // SideBar
                if state.isSidebarOpen {
                    ZStack {
                        
                        BlurEffect().ignoresSafeArea()
                        Color.bgSidebar.ignoresSafeArea()
                        
                        HStack {
                            VStack(spacing: 0) {
                                Spacer().frame(height: 42)  //높이 고정
                                Sidebar(width: $sidebarWidth)
                            }
                            .ignoresSafeArea()
                            .frame(width: 210)
                        }
                    }
                    .frame(width: sidebarWidth)
                    
                    // 너비 조정
                    ResizableEdgeView (
                        onDrag: { delta in
                            let newWidth = sidebarWidth + delta
                            sidebarWidth = max(210, min(newWidth, 400))
                        }, edge: .left
                    )
                    .frame(width: showEdge_L ? 6 : 2)
                    .background(showEdge_L ? .actionDrag : .bgSidebar)
                    .onHover(perform: { hovering in
                        showEdge_L = hovering
                    })
                    .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                        showEdge_L = isPressing
                    }, perform: {})
                }
                
                // ContentView
                ZStack {
                    Color.bgToolbar
                        .ignoresSafeArea(edges: .top)
                    if state.selectedNoteID == nil {
                        Text("Tap a note or create one")
                            .coteFont(.code1, color: .textDefault)
                    } else {
                        ContentView()
                    }
                }
            }
            .frame(alignment: .leading)
            
            // Toolbar
            .overlay(alignment: .topLeading){
                HStack(spacing: 0) {
                    SideToolbar(offset: $sidebarWidth)
                    Cote.contentToolbar(isBtnTapped: $isBtnTapped, showChat: $showChat)
                }
                .background(state.isSidebarOpen ? Color.clear : Color.bgToolbar)
            }
            .overlayPreferenceValue(TagFieldAnchorKey.self) { anchor in
                GeometryReader { proxy in
                    if contentViewModel.showTags, let anchor {
                        let rect = proxy[anchor]
                        TagSuggestionsView()
                            .onDisappear { contentViewModel.hideSuggestions() }
                            .frame(maxWidth: 400, alignment: .leading)
                            .position(x: rect.minX + 200,
                                      y: rect.maxY + 80)
                    }
                }
            }
            .ignoresSafeArea()
            
            
            Divider()
                .ignoresSafeArea()
                .frame(width: 1)
                .tint(.borderSecondary)
            
            // AI Chatbot
            if showChat {
                ResizableEdgeView (
                    onDrag: { delta in
                        let newWidth = chatViewWidth + delta
                        chatViewWidth = max(250, min(newWidth, 500))
                    }, edge: .right
                )
                .frame(width: showEdge_R ? 6 : 2)
                .background(showEdge_R ? .actionDrag : .bgSidebar)
                .onHover(perform: { hovering in
                    showEdge_R = hovering
                })
                .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                    showEdge_R = isPressing
                }, perform: {})
                
                ZStack {
                    BlurEffect().ignoresSafeArea()
                    Color.bgEditor.opacity(0.95).ignoresSafeArea()
                    
                    if #available(macOS 26.0, *) {
                        ChatView()
                            .environmentObject(ChatViewModel())
                            .ignoresSafeArea()
                    } else { }
                }
                .frame(width: chatViewWidth)
            }
        }
        .environmentObject(contentViewModel)
        .environmentObject(state)
    }
}

//MARK: - contentToolbar
private struct contentToolbar: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @EnvironmentObject private var state: UIState
    @FocusState private var isFocused: Bool
    @State private var newTag: Tag = .init(name: "")
    @State private var isSettingHover: Bool = false
    @State private var isChatHover: Bool = false
    @Binding var isBtnTapped: Bool
    @Binding var showChat: Bool
    
    private var tagChipsView: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.noteTags, id: \.self) { tag in
                TagChip(tag: tag.name){}
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 20)
            Text(viewModel.title.isEmpty ? "" : viewModel.title)
                .coteFont(.title,
                          color: .textStrong)
                .padding(.trailing, 10)
            
            if !viewModel.noteTags.isEmpty {
                tagChipsView
                    .padding(.trailing, 10)
            }
            
            if isBtnTapped {
                TextField("", text: $newTag.name)
                    .focused($isFocused)
                    .tint(.textDefault)
                    .coteFont(.tag, color: .textDefault)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .frame(minWidth: 60, alignment: .leading)
                    .fixedSize()
                    .textFieldStyle(.plain)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .anchorPreference(key: TagFieldAnchorKey.self,
                                                  value: .bounds) { $0 }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.borderDefault, lineWidth: isFocused ? 2 : 1)
                    )
                    .onSubmit(of: .text) {
                        let tagToAdd = newTag
                        if !tagToAdd.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            withAnimation(.smooth) {
                                viewModel.addNewTag(tagToAdd)
                                newTag = .init(name: "")
                                isFocused = true
                                viewModel.showSuggestions()
                            }
                        }
                    }
                    .onChange(of: isFocused, initial: false) { oldValue, newValue in
                        if !newValue && newTag.name.isEmpty {
                            withAnimation(.snappy) {
                                isBtnTapped = false
                            }
                        }
                    }
            }
            
            if !isBtnTapped && state.selectedNoteID != nil {
                Button {
                    isBtnTapped = true
                    isFocused = true
                    viewModel.showSuggestions()
                } label: {
                    Text("Add Tags")
                        .coteFont(.text2,
                                  color: .textMuted)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // setting Button
            Menu {
                Button {
                    
                } label: {
                    HStack {
                        Image(systemName: "tag")
                        Text("Edit Tags")
                    }
                }
                
                Button {
                    if let id = state.selectedNoteID {
                        viewModel.deleteNote(id: id)
                    }
                    state.selectedNoteID = state.previousNoteID
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("노트 삭제하기")
                    }
                }
                
                
            } label: {
                Image("setting")
                    .foregroundStyle(isSettingHover ? .iconSelected : .iconSecondary)
            }
            .buttonStyle(.plain)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSettingHover ? .actionSecondary : .clear)
            )
            .onHover(perform: { hovering in
                isSettingHover = hovering
            })
            .padding(.trailing, 4)
            
            // chatbot Button
            Button {
                withAnimation(.smooth){
                    showChat.toggle()
                }
            } label: {
                Image("AIChat")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isChatHover || showChat ? .aiDefault : .iconSecondary)
            }
            .buttonStyle(.plain)
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isChatHover || showChat ? .actionSecondary : .clear)
            )
            .onHover(perform: { hovering in
                isChatHover = hovering
            })
        }
        .padding(.horizontal, 15)
        .frame(height: 42)  //높이 고정
        .background(Color.bgToolbar)
    }
}

private struct TagFieldAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}


//MARK: - Sidebar
private struct Sidebar: View {
    @EnvironmentObject private var state: UIState
    @Binding var width: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.actionDefault)
                if state.isFolderView {
                    FolderView()
                }
                if state.isSearchView {
                    SearchView()
                }
            }
        }
        .frame(width: width)
        .frame(minHeight: 700)
        .background(Color.clear)
    }
}
