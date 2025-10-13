//
//  SearchView.swift
//  Cote
//
//  Created by 김예림 on 10/14/25.
//

import SwiftUI
import RealmSwift

struct NoteItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let content: String
    
    init(id: UUID = UUID(), title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all
    case title
    case content
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .all:
            return "전체"
        case .title:
            return "제목"
        case .content:
            return "내용"
        }
    }
}

struct SearchView: View {
    @State private var query: String = ""
    @State private var scope: SearchScope = .all
    
    @StateObject private var sideBarVM = SideBarViewModel()
    
    var filteredNotes: [Note] {
        // Flatten roots into a list of notes
        func flatten(_ items: [NoteItems]) -> [Note] {
            var result: [Note] = []
            for item in items {
                switch item {
                case .note(let n):
                    result.append(n)
                case .folder(let f):
                    result.append(contentsOf: f.notes)
                    result.append(contentsOf: flatten(f.children.map(NoteItems.folder)))
                }
            }
            return result
        }
        let allNotes = flatten(sideBarVM.roots)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmedQuery.isEmpty { return allNotes }
        return allNotes.filter { n in
            let title = n.title.lowercased()
            let content = n.content.lowercased()
            switch scope {
            case .all:
                return title.contains(trimmedQuery) || content.contains(trimmedQuery)
            case .title:
                return title.contains(trimmedQuery)
            case .content:
                return content.contains(trimmedQuery)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("검색 범위", selection: $scope) {
                    ForEach(SearchScope.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if #available(iOS 17.0, *) {
                    TextField("검색어를 입력하세요", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .padding(Edge.Set.horizontal)
                } else {
                    TextField("검색어를 입력하세요", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .padding(Edge.Set.horizontal)
                }
                
                List(filteredNotes, id: \.id) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.content)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .overlay(
                    Group {
                        if filteredNotes.isEmpty {
                            if #available(iOS 17.0, *) {
                                ContentUnavailableView(
                                    "결과가 없습니다",
                                    systemImage: "magnifyingglass",
                                    description: Text("다른 검색어나 범위를 시도해 보세요")
                                )
                                .padding()
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text("결과가 없습니다")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("다른 검색어나 범위를 시도해 보세요")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        } else {
                            EmptyView()
                        }
                    }
                )
            }
            .animation(.default, value: query)
            .animation(.default, value: scope)
        }
    }
}

#Preview {
    SearchView()
}
