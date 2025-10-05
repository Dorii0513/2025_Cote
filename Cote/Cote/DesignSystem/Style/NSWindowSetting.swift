//
//  NSWindowSetting.swift
//  Cote
//
//  Created by 김예림 on 9/6/25.
//

import SwiftUI
import AppKit

struct WindowConfigurator_1: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                
                // 타이틀바 숨기고 전체 뷰 확장
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                
                // 컨트롤 버튼 숨기기
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                
                window.toolbar = nil
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct WindowConfigurator_2: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let w = v.window {
                w.appearance = NSAppearance(named: .aqua)
                w.titlebarAppearsTransparent = false
                w.isOpaque = true
                w.backgroundColor = .windowBackgroundColor
                w.toolbarStyle = .unified
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
