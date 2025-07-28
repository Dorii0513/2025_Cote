//
//  VisualEffectView.swift
//  Cote
//
//  Created by 김예림 on 7/28/25.
//

import Foundation
import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        effectView.material = .hudWindow
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}
