//
//  SearchView.swift
//  Cote
//
//  Created by 김예림 on 10/14/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var state: UIState
    @FocusState private var focusField: FocusTarget?
    
    @State private var changeMode: Bool = true
    
    @State private var isSortHover: Bool = false
    @State private var isSearchHover: Bool = false
    @State private var isOptionHover: Bool = false
    @State private var isFilterHover: Bool = false
    
    @State private var showOption: Bool = false
    @State private var glow = false
    
    private var isFocused: Bool {
        get { focusField == .search }
        set { focusField = newValue ? .search : nil }
    }
    
    private var borderColor: Color {
        if isFocused && viewModel.mode == .semantic {
            return .textTag.opacity(0.7)
        }
        if isFocused && viewModel.mode == .keyword {
            return .borderDefault.opacity(0.8)
        }
        if !isFocused && viewModel.mode == .semantic {
            return .textTag.opacity(0.4)
        }
        return .borderSecondary.opacity(0.5)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 8)
            
            // 검색창
            HStack(spacing: 6) {
                Button {
                    withAnimation(.linear(duration: 0.2)) {
                        viewModel.toggleSearchMode()
                    }
                    
                    withAnimation(
                        .smooth(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        glow = true
                    }
                } label: {
                    Image("AISearch")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundColor(isSearchHover || viewModel.mode == .semantic ? .textTag : .iconDefault)
                        .padding(.bottom, 2)     // 균형 맞추기 용
                        .padding(.horizontal, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundStyle(isSearchHover ? .actionDefault : .clear)
                        )
                }
                .onHover(perform: { hovering in
                    isSearchHover = hovering
                })
                .buttonStyle(.plain)
                .padding(.leading, 1)
                TextField("Search your notes", text: $viewModel.query)
                    .focused($focusField, equals: .search)
                    .coteFont(.text2, color: .textSelected)
                    .tint(.textDefault)
                    .textFieldStyle(.plain)
                    .onSubmit(of: .text) {
                        withAnimation(.easeInOut) {
                            focusField = nil
                        }
                    }
                Spacer()
                
                Button{
                    viewModel.cleanQuery()
                } label: {
                    Image("xBtn")
                }
                .buttonStyle(.plain)
            }
            .padding([.vertical, .horizontal], 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.bgTextField)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .shadow(color: viewModel.mode == .semantic ? .textTag.opacity(glow ? 0.4 : 0.8) : .clear, radius: glow ? 5 : 2, x: 0, y: 0)
            )
            .padding(.vertical, 4)
            
            Spacer().frame(height: 8)
            
            // 정렬
            HStack(spacing: 0) {
                Text("\(viewModel.resultCount)개의 노트")
                    .coteFont(.text3, color: .textSecondary)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut) {
                        showOption.toggle()
                    }
                } label: {
                    Image("filter2")
                        .foregroundStyle(isOptionHover ? .iconSelected : .iconSecondary)
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(isOptionHover ? .actionDefault : .clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover(perform: { hovering in
                    isOptionHover = hovering
                })
            }
            .padding(.leading, 8)
            
            Spacer().frame(height: 4)
            
            // 필터
            if showOption {
                HStack(spacing: 3) {
                    Menu {
                        Button {
                            viewModel.setSort(.newest)
                        } label: {
                            Label("Newest", systemImage: viewModel.sort == .newest ? "checkmark" : "")
                        }
                        
                        Button {
                            viewModel.setSort(.oldest)
                        } label: {
                            Label("Oldest", systemImage: viewModel.sort == .oldest ? "checkmark" : "")
                        }
                        
                        if viewModel.mode == .semantic {
                            Button {
                                viewModel.setSort(.relevance)
                            } label: {
                                Label("Relevance", systemImage: viewModel.sort == .relevance ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.sort.rawValue)
                                .coteFont(.text2, color: isSortHover ? .textDefault : .textSecondary)
                            
                            Image(systemName: "chevron.down")
                                .foregroundStyle(isSortHover ? .iconDefault : .iconMuted)
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(isSortHover ? .actionDefault.opacity(0.5) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover(perform: { hovering in
                        isSortHover = hovering
                    })
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
                    
                    if viewModel.mode == .keyword {
                        Menu {
                            Button {
                                viewModel.setFilter(.note)
                            } label: {
                                Label("Title", systemImage: viewModel.filter == .note ? "checkmark" : "")
                            }
                            
                            Button {
                                viewModel.setFilter(.folder)
                            } label: {
                                Label("Folder", systemImage: viewModel.filter == .folder ? "checkmark" : "")
                            }
                            
                            Button {
                                viewModel.setFilter(.content)
                            } label: {
                                Label("Content", systemImage: viewModel.filter == .content ? "checkmark" : "")
                            }
                            
                            Button {
                                viewModel.setFilter(.tag)
                            } label: {
                                Label("Tag", systemImage: viewModel.filter == .tag ? "checkmark" : "")
                            }
                            
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.filter.rawValue)
                                    .coteFont(.text2, color: isFilterHover ? .textDefault : .textSecondary)
                                
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(isFilterHover ? .iconDefault : .iconMuted)
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundStyle(isFilterHover ? .actionDefault.opacity(0.5) : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .onHover(perform: { hovering in
                            isFilterHover = hovering
                        })
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                        )
                    }
                    Spacer()
                }
            }
            
            Spacer().frame(height: 8)
            
            // 검색 결과 리스트
            if viewModel.results.isEmpty {
                Spacer()
                VStack {
                    Text("No results found.")
                        .coteFont(.text1, color: .textSecondary)
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.results) { result in
                        SearchCell(selectedNoteID: state.selectedNoteID, result: result) {
                            state.selectedNoteID = result.noteID
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 10)
        .onAppear(){
            focusField = .search
        }
        // focus 해제
        .contentShape(Rectangle())
        .onTapGesture {
            focusField = nil
        }
    }
}
