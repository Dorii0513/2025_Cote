//
//  SearchCell.swift
//  Cote
//
//  Created by 김예림 on 11/10/25.
//

import Foundation
import SwiftUI

struct SearchCell: View {
    @State var isHover: Bool = false
    var result: SearchResult
    let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .coteFont(.text1, color: .textDefault)
                    
                    if !result.folders.isEmpty {
                        HStack(spacing: 2) {
                            Image("folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12,height: 12)
                                .foregroundStyle(.iconSecondary)
                            
                            Text(result.folders.joined(separator: " / "))
                                .coteFont(.text3, color: .textSecondary)
                        }
                    }
                    //                            HStack {
                    //                                Spacer()
                    //                                Text(String(format: "유사도: %.2f", result.score))
                    //                                    .font(.caption)
                    //                                    .foregroundColor(.gray)
                    //                            }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(isHover ? .actionDefault : .clear)
            )
            .onHover { isHover = $0 }
        }
        .buttonStyle(.plain)
    }
}
