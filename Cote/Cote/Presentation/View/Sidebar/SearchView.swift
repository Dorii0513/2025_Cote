//
//  SearchView.swift
//  Cote
//
//  Created by 김예림 on 10/14/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색창
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("검색어를 입력하세요...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                        .frame(height: 28)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.gray80))
                )
                .padding(.horizontal)
                .padding(.top, 12)

                Divider().padding(.vertical, 4)

                // 검색 결과 리스트
                if viewModel.results.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.gray)
                        Text("검색 결과가 없습니다.")
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    Spacer()
                } else {
                    List(viewModel.results, id: \.noteID) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(result.title)
                                .font(.headline)
                            Text(result.preview)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            HStack {
                                Spacer()
                                Text(String(format: "유사도: %.2f", result.score))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("노트 검색")
        }
    }
}

