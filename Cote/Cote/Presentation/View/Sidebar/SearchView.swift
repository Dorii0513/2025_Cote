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

    var body: some View {
            VStack(spacing: 8) {
                Spacer().frame(height: 0)
                
                // 검색창
                HStack(spacing: 4) {
                    Image("search")
                        .foregroundColor(.iconSecondary)
                    TextField("Search your notes", text: $viewModel.query)
                        .coteFont(.text2, color: .textSelected)
                        .textFieldStyle(.plain)
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
                                .stroke(Color.borderSecondary, lineWidth: 2)
                        )
                )
                .padding(.vertical, 4)
                
                HStack {
                    Text("\(viewModel.resultCount)개의 노트")
                        .coteFont(.text3, color: .textSecondary)
                    Spacer()
                    Button {
                        // 필터 액션
                    } label: {
                        Image("filter2")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 3)

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
                            SearchCell(result: result) {
                                state.selectedNoteID = result.noteID
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 10)
    }
}

