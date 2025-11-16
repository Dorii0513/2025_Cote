//
//  HomeView.swift
//  Cote
//
//  Created by 김예림 on 7/26/25.
//

import SwiftUI
import AppKit

struct HomeView: View {
    @State private var isBtnTapped: Bool = false
    @State private var sidebarWidth: CGFloat = 210
    @State private var showEdge: Bool = false
    @State private var showChat: Bool = false
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var state = UIState()
    
    var body: some View {
        HStack {
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
                    ResizableEdgeView { delta in
                        let newWidth = sidebarWidth + delta
                        sidebarWidth = max(210, min(newWidth, 400))
                    }
                    .frame(width: showEdge ? 6 : 2)
                    .background(showEdge ? .bgTag : .bgSidebar)
                    .onHover(perform: { hovering in
                        showEdge = hovering
                    })
                    .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                        showEdge = isPressing
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
                    if viewModel.showTags, let anchor {
                        let rect = proxy[anchor]
                        TagSuggestionsView()
                            .onDisappear { viewModel.hideSuggestions() }
                            .frame(maxWidth: 400, alignment: .leading)
                            .position(x: rect.minX + 200,
                                      y: rect.maxY + 80)
                    }
                }
            }
            .environmentObject(viewModel)
            .environmentObject(state)
            .ignoresSafeArea()
            
            //TODO: - contentView 너비 조정 기능 추가
            // AI Chatbot
            if showChat {
                ZStack {
                    BlurEffect().ignoresSafeArea()
                    Color.bgSidebar.ignoresSafeArea()
                    
                    ChatView(message: "")
                }
                .frame(minWidth: 210)
                .frame(maxWidth: 320)
            }
        }
        
    }
}

//MARK: - contentToolbar
private struct contentToolbar: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @EnvironmentObject private var state: UIState
    @FocusState private var isFocused: Bool
    @State private var newTag: Tag = .init(name: "")
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
            } label: {
                Image("setting")
                
            }
            .buttonStyle(.plain)
            
            // chatbot Button
            Button {
                withAnimation(.easeInOut){
                    showChat.toggle()
                }
            } label: {
                
                Image("generate_line")
            }
            .buttonStyle(.plain)
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
