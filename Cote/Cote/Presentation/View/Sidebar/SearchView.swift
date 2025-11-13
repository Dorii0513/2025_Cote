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
    @State private var sort: SearchFilter = .newest
    @State private var isFilterHover: Bool = false
    
    private var isFocused: Bool {
        get { focusField == .search }
        set { focusField = newValue ? .search : nil }
    }
    
    var body: some View {
            VStack(spacing: 8) {
                Spacer().frame(height: 0)
                
                // 검색창
                HStack(spacing: 4) {
                    Image("search")
                        .foregroundColor(.iconSecondary)
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
                                .stroke(isFocused ? Color.borderDefault : Color.borderSecondary, lineWidth: 2)
                        )
                )
                .padding(.vertical, 4)
                
                HStack {
                    Text("\(viewModel.resultCount)개의 노트")
                        .coteFont(.text3, color: .textSecondary)
                    Spacer()
                    Menu {
                        Button {
                            sort = .newest
                        } label: {
                            Label("최신순", systemImage: sort == .newest ? "checkmark" : "")
                        }
                        Button {
                            sort = .oldest
                        } label: {
                            Label("오래된순", systemImage: sort == .oldest ? "checkmark" : "")
                        }
                        Button {
                            sort = .relevance
                        } label: {
                            Label("관련도순", systemImage: sort == .relevance ? "checkmark" : "")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(sort.rawValue)
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

enum SearchFilter: String {
    case newest = "Newest"
    case oldest = "Oldest"
    case relevance = "Relevance"
}
