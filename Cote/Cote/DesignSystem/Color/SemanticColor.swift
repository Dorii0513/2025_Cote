//
//  SemanticColor.swift
//  Cote
//
//  Created by 김예림 on 7/16/25.
//

import SwiftUI

struct DesignColor {
    
    struct icon {
        static let `default` = Color("gray80")
        static let selected = Color("gray50")
        static let strong = Color("gray70")
        static let secondary = Color("gray90")
    }
    
    struct text {
        static let `default` = Color("gray50")
        static let label_selected = Color("gray50")
        static let label_default = Color("gray80")
        static let label_secondary = Color("gray60")
        static let label_info = Color("gray100")
        static let tag_selected = Color("gray70")
        static let tag_default = Color("gray80")
    }
    
    struct bg {
        static let tag = Color("gray80-15%")
        static let input_default = Color("black90")
        static let elevated_default = Color("black70")
        static let surface_gutter = Color("black100")
        static let surface_toolbar = Color("black80")
        static let surface_sidebar = Color("black100-95%")
        static let surface_scroll = Color("black70")
        static let surface_bar = Color("gray90")
    }
    
    struct action {
        static let `default` = Color("gray80-10%")
    }
}
