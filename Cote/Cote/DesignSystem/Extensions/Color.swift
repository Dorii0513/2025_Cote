//
//  Color.swift
//  Cote
//
//  Created by 김예림 on 7/16/25.
//

import SwiftUI

extension ShapeStyle where Self == Color {
    static var borderDefault: Self { Color("gray90") }
    static var borderSecondary: Self { Color("black60") }
    
    // icon
    static var iconDefault: Self { Color("gray80") }
    static var iconSelected: Self { Color("gray50") }
    static var iconStrong:   Self { Color("gray70") }
    static var iconSecondary:Self { Color("gray90") }
    
    // text
    static var textStrong:       Self { Color("gray50") }
    static var textSelected: Self { Color("gray50") }
    static var textDefault:  Self { Color("gray80") }
    static var textSecondary:     Self { Color("gray100") }
    static var textMuted:Self { Color("gray100") }
    static var textTag:   Self { Color("purple20") }
    
    // background
    static var bgTextField: Self { Color("black200_8") }
    static var bgTag:            Self { Color("purple100_15") }
    static var bgEditor:   Self { Color("black100") }
    static var bgElevatedDefault:Self { Color("black70") }
    static var bgGutter:  Self { Color("black200") }
    static var bgToolbar: Self { Color("black90") }
    static var bgSidebar: Self { Color("black90_80") }
    static var bgSurfaceScroll:  Self { Color("black70") }
    static var bgSurfaceBar:     Self { Color("gray90") }
    
    // action
    static var actionDefault: Self { Color("gray80_10pct") }
}
