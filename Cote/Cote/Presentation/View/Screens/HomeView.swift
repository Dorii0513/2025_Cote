//
//  HomeView.swift
//  Cote
//
//  Created by 김예림 on 7/26/25.
//

import SwiftUI
import AppKit

@available(macOS 26.0, *)
struct HomeView: View {
    @State private var sidebarWidth: CGFloat = 210
    @State private var chatViewWidth: CGFloat = 250
    
    @State private var isBtnTapped: Bool = false
    @State private var showEdge_L: Bool = false
    @State private var showEdge_R: Bool = false
    @State private var showChat: Bool = false
    
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var state = UIState()
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                if state.isSidebarOpen {
                    sideBarwithResizable
                }
                
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
            .overlay(alignment: .topLeading) {
                ZStack {
                    HStack(spacing: 0) {
                        SideToolbar(offset: $sidebarWidth)
                        Cote.contentToolbar(isBtnTapped: $isBtnTapped, showChat: $showChat)
                    }
                    .background(state.isSidebarOpen ? Color.clear : Color.bgToolbar)
                }
            }
            .overlayPreferenceValue(TagChipsAnchorKey.self) { anchor in
                GeometryReader { proxy in
                    if contentViewModel.showTags, let anchor {
                        let rect = proxy[anchor]
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    contentViewModel.hideSuggestions()
                                }
                            }
                        TagView()
                            .frame(width: 400, height: 100, alignment: .topLeading)
                            .offset(x: rect.minX, y: 0)
                    }
                }
            }
            .ignoresSafeArea()
            
            Divider()
                .ignoresSafeArea()
                .frame(width: 1)
                .tint(.borderSecondary)
            
            if showChat {
                chatViewiwthResizable
            }
        }
        .environmentObject(contentViewModel)
        .environmentObject(state)
        .environmentObject(chatViewModel)
    }
    
    
    //MARK: - sideBar_Resizable
    @ViewBuilder
    private var sideBarwithResizable: some View {
        ZStack {
            
            BlurEffect().ignoresSafeArea()
            Color.bgSidebar.ignoresSafeArea()
            
            HStack {
                VStack(spacing: 0) {
                    Spacer().frame(height: 42)  //높이 고정
                    SidebarView(width: $sidebarWidth)
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
    
    //MARK: - chatView_Resizable
    @ViewBuilder
    private var chatViewiwthResizable: some View {
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
                    .ignoresSafeArea()
            } else { }
        }
        .frame(width: chatViewWidth)
    }
}
