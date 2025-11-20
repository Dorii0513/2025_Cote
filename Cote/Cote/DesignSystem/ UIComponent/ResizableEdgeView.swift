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
    var edge: ResizableEdge

    func makeNSView(context: Context) -> NSView {
        let view = CursorTrackingView()
        view.onDrag = onDrag
        view.edge = edge
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class CursorTrackingView: NSView {
    var onDrag: ((CGFloat) -> Void)?
    var edge: ResizableEdge? = .left

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
        var delta: CGFloat = .zero
        if edge == .left {
            delta = newLocation.x - last.x
        } else {
            delta = last.x - newLocation.x
        }
        lastLocation = newLocation
        onDrag?(delta)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        lastLocation = nil
    }
}

enum ResizableEdge: Hashable {
    case left
    case right
}
