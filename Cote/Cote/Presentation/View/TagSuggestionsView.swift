//
//  TagSuggestionsView.swift
//  Cote
//
//  Created by 김예림 on 9/9/25.
//

import SwiftUI

struct TagSuggestionsView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    private var suggestionsView: some View {
        VStack(alignment: .leading) {
            Text("Tap to add relevant tags for this note.")
                .coteFont(.title2, color: .textDefault)
            if viewModel.generatedTags.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Generating tags…")
                        .coteFont(.title2, color: .textInfo)
                        .foregroundStyle(Color.textDefault)
                }
                .padding(.vertical, 4)
            }
            HStack(spacing: 6) {
                ForEach(viewModel.generatedTags, id: \.self) { tag in
                    TagChip(tag: tag.name){
                        viewModel.addNewTag(tag)
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            BlurEffect()
            Color.bgSidebar
            if viewModel.content.isEmpty {
                Text("노트를 입력해 주세요")
                    .coteFont(.title2, color: .textDefault)
                    .padding(.leading, 10)
            } else {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Image("generate")
                        Text("AI-Generated Tags")
                            .coteFont(.title2, color: .textStrong)
                    }
                    .padding(.bottom, 10)
                    suggestionsView
                        .padding(.leading, 15)
                }
                .padding(.top, 8)
                .padding([.bottom, .horizontal], 15)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(height: 80)
    }
}

#Preview {
    TagSuggestionsView()
}
