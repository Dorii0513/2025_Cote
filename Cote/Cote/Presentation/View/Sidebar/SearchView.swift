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
    
    @State private var showFilter: Bool = false
    @State private var isFilterHover: Bool = false
    @State private var changeMode: Bool = true
    @State private var isHover: Bool = false
    
    private var isFocused: Bool {
        get { focusField == .search }
        set { focusField = newValue ? .search : nil }
    }
    
    private var borderColor: Color {
        if isFocused && viewModel.mode == .semantic {
            return .textTag
        }
        if isFocused && viewModel.mode == .keyword {
            return .borderDefault
        }
        if !isFocused && viewModel.mode == .semantic {
            return .textTag.opacity(0.5)
        }
        return .borderSecondary
    }
    
    var body: some View {
            VStack(spacing: 8) {
                Spacer().frame(height: 0)
                
                // 검색창
                HStack(spacing: 6) {
                    Button {
                        viewModel.toggleSearchMode()
                    } label: {
                        Image("AISearch")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(isHover || viewModel.mode == .semantic ? .textTag : .iconDefault)
                            .padding(.bottom, 2)     // 균형 맞추기 용
                            .padding(.horizontal, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(isHover ? .actionDefault : .clear)
                            )
                    }
                    .onHover(perform: { hovering in
                        isHover = hovering
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
                        .fill(Color(.bgTextField))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: 2)
                        )
                        .shadow(color: viewModel.mode == .semantic ? .textTag.opacity(0.5) : .clear, radius: 4, x: 0, y: 0)
                )
                .padding(.vertical, 4)
                
                HStack {
                    Text("\(viewModel.resultCount)개의 노트")
                        .coteFont(.text3, color: .textSecondary)
                    Spacer()
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
                                .coteFont(.text2, color: isFilterHover ? .textDefault : .textSecondary)

                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(isFilterHover ? .iconDefault : .iconSecondary)
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .foregroundStyle(isFilterHover ? .actionDefault : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover(perform: { hovering in
                        isFilterHover = hovering
                    })
                }
                .padding(.leading, 3)

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
