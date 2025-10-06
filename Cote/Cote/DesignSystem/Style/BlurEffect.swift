//
//  VisualEffectView.swift
//  Cote
//
//  Created by 김예림 on 7/28/25.
//

import Foundation
import SwiftUI

struct BlurEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effect = NSVisualEffectView()
        effect.state = .active
        effect.blendingMode = .behindWindow
        effect.material = .fullScreenUI
        return effect
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}
