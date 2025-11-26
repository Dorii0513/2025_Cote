//
//  TagView.swift
//  Cote
//
//  Created by 김예림 on 11/26/25.
//

import SwiftUI

struct TagView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @State private var newTag: Tag = .init(name: "")
    
    private var addTags: Bool {
        if viewModel.noteTags.count < 3 {
            return true
        } else { return false }
    }
    
    @FocusState var isFocused: Bool
    //    @Binding var tags: [Tag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if !viewModel.noteTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(viewModel.noteTags, id: \.self) { tag in
                            TagChip(tag: tag.name,
                                    isSugesstion: false,
                                    isDeletable: true,
                                    onDelete: {
                                if let id = viewModel.currentNoteID {
                                    Task {
                                        await viewModel.deleteTag(noteID: id, tagName: tag.name)
                                    }
                                }
                            },
                                    onSelect: {}
                            )
                        }
                    }
                    .padding(.trailing, 4)
                }
                if addTags {
                    TextField("", text: $newTag.name)
                        .focused($isFocused, equals: true)
                        .textFieldStyle(.plain)
                        .coteFont(.text2, color: .textSelected)
                        .tint(.actionFocus)
                        .onSubmit(of: .text) {
                            let tagToAdd = newTag
                            if !tagToAdd.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withAnimation(.smooth) {
                                    viewModel.addNewTag(tagToAdd)
                                    newTag = .init(name: "")
                                    viewModel.showSuggestions()
                                    isFocused = true
                                }
                            }
                        }
                }
            }
            .frame(height: 42)
            .padding(.horizontal, 12)
            .background(.bgToolbar)
            
            Divider()
                .tint(.textSecondary)
            
            Spacer(minLength: 6)
            
            if addTags {
                suggestionView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            } else {
                Text("You can add up to three tags.")
                    .coteFont(.text2, color: .textSecondary)
                    .padding(.horizontal, 12)
                Spacer()
            }
        }
        .background(.bgTagSugesstion)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black200, radius: 5)
        .onAppear() {
            isFocused = true
        }
    }
    
    @ViewBuilder
    private var suggestionView: some View {
        VStack(alignment: .leading) {
            
            HStack(spacing: 4) {
                Image(systemName: "sparkles.2")
                Text("AI-Generated Tags")
                    .coteFont(.text2, color: .textStrong)
            }
            
            Spacer(minLength: 16)
            
            Text("Tap to add relevant tags for this note.")
                .coteFont(.text3, color: .textSecondary)
                .padding(.bottom, 2)
            
            if viewModel.generatedTags.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Generating tags…")
                        .coteFont(.text2, color: .textSecondary)
                        .foregroundStyle(Color.textDefault)
                }
                .padding(.vertical, 4)
            }
            CustomChipLayout(spacing: 6) {
                ForEach(viewModel.generatedTags, id: \.self) { tag in
                    TagChip(tag: tag.name,
                            isSugesstion: true,
                            isDeletable: false,
                            onDelete: {},
                            onSelect: {
                        viewModel.addNewTag(tag)
                    })
                }
            }
        }
    }
}


//#Preview {
//    TagView(tags: .constant([Tag(name: "hi")]))
//}
