//
//  ContentToolbar.swift
//  Cote
//
//  Created by 김예림 on 11/24/25.
//

import SwiftUI

struct contentToolbar: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @EnvironmentObject private var state: UIState
    
    @FocusState var focusField: FocusTarget?
    @State private var showTagField: Bool = false
    @State private var showTitleField: Bool = false
    
    @State private var newTitle: String = ""
    @State private var newTag: Tag = .init(name: "")
    
    @State private var isSettingHover: Bool = false
    @State private var isChatHover: Bool = false
    
    @State private var showTagView: Bool = false
    
    @Binding var isBtnTapped: Bool
    @Binding var showChat: Bool
    
    private var tagChipsView: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.noteTags, id: \.self) { tag in
                TagChip(tag: tag.name,
                        isSugesstion: false,
                        isDeletable: false,
                        onDelete: {},
                        onSelect: {}
                )
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .anchorPreference(key: TagChipsAnchorKey.self,
                                      value: .bounds) { $0 }
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 20)
            
            if showTitleField {
                HStack {
                    TextField("", text: $newTitle)
                        .coteFont(.title, color: .textSelected)
                        .tint(.actionFocus)
                        .focused($focusField, equals: .note)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.bgTextField)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.borderDefault, lineWidth: 2)
                        )
                )
                .frame(width: 200)
                .padding(.trailing, 10)
                .onSubmit(of: .text) {
                    withAnimation(.easeInOut) {
                        if !newTitle.isEmpty {
                            viewModel.title = newTitle
                        }
                        focusField = nil
                        showTitleField = false
                        newTitle = ""
                    }
                }
            } else {
                Text(viewModel.title.isEmpty ? "" : viewModel.title)
                    .coteFont(.title,
                              color: .textStrong)
                    .padding(.trailing, 10)
            }
            
            tagChipsView
                .padding(.trailing, 10)
            
            
            if showTagField {
                TextField("", text: $newTag.name)
                    .focused($focusField, equals: .tag)
                    .tint(.actionFocus)
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
                            .stroke(Color.borderDefault, lineWidth: showTagField ? 2 : 1)
                    )
                    .onSubmit(of: .text) {
                        let tagToAdd = newTag
                        if !tagToAdd.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            withAnimation(.smooth) {
                                viewModel.addNewTag(tagToAdd)
                                newTag = .init(name: "")
                                showTagField = true
                                viewModel.showSuggestions()
                            }
                        }
                    }
            }
            
            Spacer()
            
            // setting Button
            Menu {
                Button {
                    viewModel.showTags = true
                } label: {
                    HStack {
                        Image(systemName: "tag")
                        Text("Edit Tags")
                    }
                }
                
                Button {
                    withAnimation(.snappy) {
                        newTitle = viewModel.title
                        showTitleField = true
                        focusField = .note
                    }
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Rename Note")
                    }
                }
                
                Divider()
                
                Button {
                    if let id = state.selectedNoteID {
                        viewModel.deleteNote(id: id)
                    }
                    state.selectedNoteID = state.previousNoteID
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Note")
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
        .onChange(of: focusField) { _, newValue in
            if newValue != .tag && newTag.name.isEmpty {
                withAnimation(.snappy) {
                    showTagField = false
                }
            }
            if newValue != .note && newTitle == viewModel.title {
                withAnimation(.snappy) {
                    showTitleField = false
                }
            }
        }
        .onChange(of: viewModel.showTags) { _, newValue in
            if newValue {
                viewModel.showSuggestions()
            } else {
                viewModel.hideSuggestions()
            }
        }
    }
}

struct TagFieldAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

struct TagChipsAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
