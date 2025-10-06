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
            Text(": create new Tag")
                .coteFont(.title2, color: .textDefault)
            HStack(spacing: 6) {
                ForEach(viewModel.generatedTags, id: \.self) { tag in
                    TagChip(tag: tag){
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
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Image("generate")
                    Text("AI Suggestions")
                        .coteFont(.title2, color: .textStrong)
                }
                suggestionsView
            }
            .padding(.top, 8)
            .padding([.bottom, .horizontal], 15)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(minWidth: 205)
        .frame(height: 80)
    }
}

#Preview {
    TagSuggestionsView()
}
