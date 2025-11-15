//
//  ResizableEdgeView.swift
//  Cote
//
//  Created by 김예림 on 11/14/25.
//

import Foundation
import SwiftUI

struct ResizableEdgeView: NSViewRepresentable {
    var onDrag: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = CursorTrackingView()
        view.onDrag = onDrag
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class CursorTrackingView: NSView {
    var onDrag: ((CGFloat) -> Void)?

    private var isDragging = false
    private var lastLocation: NSPoint?

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        lastLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let last = lastLocation else { return }
        let newLocation = event.locationInWindow
        let delta = newLocation.x - last.x
        lastLocation = newLocation
        onDrag?(delta)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        lastLocation = nil
    }
}
