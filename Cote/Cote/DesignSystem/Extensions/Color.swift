//
//  Color.swift
//  Cote
//
//  Created by 김예림 on 7/16/25.
//

import SwiftUI

extension ShapeStyle where Self == Color {
    // icon
    static var iconDefault: Self { Color("gray80") }
    static var iconSelected: Self { Color("gray50") }
    static var iconStrong:   Self { Color("gray70") }
    static var iconSecondary:Self { Color("gray90") }
    
    // text
    static var textDefault:       Self { Color("gray50") }
    static var textLabelSelected: Self { Color("gray50") }
    static var textLabelDefault:  Self { Color("gray80") }
    static var textLabelSecondary:Self { Color("gray60") }
    static var textLabelInfo:     Self { Color("gray100") }
    static var textTagSelected:   Self { Color("gray70") }
    static var textTagDefault:    Self { Color("gray80") }
    
    // background
    static var bgTag:            Self { Color("gray80_15pct") }
    static var bgInputDefault:   Self { Color("black90") }
    static var bgElevatedDefault:Self { Color("black70") }
    static var bgSurfaceGutter:  Self { Color("black100") }
    static var bgSurfaceToolbar: Self { Color("black80") }
    static var bgSurfaceSidebar: Self { Color("black100_95pct") }
    static var bgSurfaceScroll:  Self { Color("black70") }
    static var bgSurfaceBar:     Self { Color("gray90") }
    
    // action
    static var actionDefault: Self { Color("gray80_10pct") }
}
