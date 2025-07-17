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
    case title1
    case title2
    case code1
    case code2
    
    //font
    static let pretendardSemiBoldFont: String = "Pretendard-SemiBold"
    static let pretendardMediumFont: String = "Pretendard-Medium"
    static let pretendardRegularFont: String = "Pretendard-Regular"
    static let JetBrainsMonoMedium: String = "JetBrainsMono-Medium"
    static let JetBrainsMonoRegular: String = "JetBrainsMono-Regular"
    
    //size
    static let head: CGFloat = 20
    static let bodyM: CGFloat = 15
    static let bodyS: CGFloat = 13
    
    var font: String {
        switch self {
        case .input, .tag, .title2:
            return CoteFontType.pretendardMediumFont
        case .gutter:
            return CoteFontType.pretendardRegularFont
        case .title1:
            return CoteFontType.pretendardSemiBoldFont
        case .code1:
            return CoteFontType.JetBrainsMonoMedium
        case .code2:
            return CoteFontType.JetBrainsMonoRegular
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .input, .title2, .code1, .code2:
            return CoteFontType.bodyM
        case .tag, .gutter:
            return CoteFontType.bodyS
        case .title1:
            return CoteFontType.head
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
