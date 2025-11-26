//
//  BottomBar.swift
//  Cote
//
//  Created by 김예림 on 11/26/25.
//

import SwiftUI
import Highlightr

struct BottomBar: View {
    let date: Date?
    let highlightr = Highlightr()!
    @Binding var language: String
    let onSelect: (String) -> Void
    
    @State private var isHover: Bool = false

    var body: some View {
        let languages = highlightr.supportedLanguages()
        
        HStack {
            HStack(spacing: 15) {
                if let date {
                    Text(date, style: .date)
                    Text(date, style: .time)
                } else {
                    Text("")
                }
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                // language 선택
                Menu {
                    ForEach(languages, id: \.self) { select in
                        Button {
                            onSelect(select)
                        } label: {
                            HStack {
                                Text(select)
                                if select == language {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .frame(height: 100)
                } label: {
                    HStack(spacing: 4) {
                        Text(language)
                            .coteFont(.code2, color: .textMuted)
                    }
                }
                .menuStyle(.borderlessButton)
                .tint(isHover ? .textDefault : .textMuted)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.actionDefault)
                        .opacity(isHover ? 1.0 : 0)
                )
                .onHover(perform: { hover in
                    isHover = hover
                })
            }
        }
        .coteFont(.code2, color: .textMuted)
        .padding(.leading, 15)
        .padding([.vertical, .trailing], 8)
        .background(.bgEditor)
    }
}
