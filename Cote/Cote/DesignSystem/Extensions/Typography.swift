//
//  Typography.swift
//  Cote
//
//  Created by 김예림 on 7/17/25.
//

import SwiftUI
import AppKit

public enum CoteFontType {
    case input
    case tag
    case gutter
    case title
    case text1
    case text2
    case text3
    case code1
    case code2
    case markL
    case markM
    case markS
    case mark
    
    //font
    static let pretendardSemiBoldFont: String = "Pretendard-SemiBold"
    static let pretendardMediumFont: String = "Pretendard-Medium"
    static let pretendardRegularFont: String = "Pretendard-Regular"
    static let JetBrainsMonoMedium: String = "JetBrainsMono-Medium"
    static let JetBrainsMonoRegular: String = "JetBrainsMono-Regular"
    
    //size
    static let markdownL: CGFloat = 20
    static let markdownM: CGFloat = 18
    static let markdownS: CGFloat = 16
    
    static let head: CGFloat = 16
    static let bodyL: CGFloat = 14
    static let bodyM: CGFloat = 12
    static let bodyS: CGFloat = 11
    static let caption: CGFloat = 10
    
    var font: String {
        switch self {
        case .input, .text1, .text2, .tag, .text3:
            return CoteFontType.pretendardMediumFont
        case .gutter, .mark :
            return CoteFontType.pretendardRegularFont
        case .title, .markL, .markM, .markS:
            return CoteFontType.pretendardSemiBoldFont
        case .code1 :
            return CoteFontType.JetBrainsMonoMedium
        case .code2:
            return CoteFontType.JetBrainsMonoRegular
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .text1:
            return CoteFontType.bodyL
        case .input, .text2, .code1, .code2, .tag:
            return CoteFontType.bodyM
        case .text3:
            return CoteFontType.bodyS
        case .gutter:
            return CoteFontType.caption
        case .title:
            return CoteFontType.head
        case .mark:
            return CoteFontType.bodyL
        case .markL:
            return CoteFontType.markdownL
        case .markM:
            return CoteFontType.markdownM
        case .markS:
            return CoteFontType.markdownS
        }
    }
}

extension View {
    func coteFont(_ type: CoteFontType, color: Color) -> some View {
        self
            .font(.custom(type.font, size: type.fontSize))
            .foregroundColor(color)
    }
}
