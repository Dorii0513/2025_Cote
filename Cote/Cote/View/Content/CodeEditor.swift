//
//  Editor.swift
//  Cote
//
//  Created by 김예림 on 8/10/25.
//

import SwiftUI
import AppKit

// MARK: - SwiftUI Code Editor
public struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    
    public init(
        text: Binding<String>,
        font: NSFont = NSFont(name: "JetBrainsMono-Regular", size: 14)
        ?? .monospacedSystemFont(ofSize: 14, weight: .regular)
    ) {
        self._text = text
        self.font = font
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        
        // Create text system
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude // ⬅️ CGFloat로 명시
        )

        textContainer.lineFragmentPadding = 0 // ⬅️ 추가: 내부 좌우 패딩 제거
        layoutManager.addTextContainer(textContainer)

        
        // Create text view
        let textView = CodeTextView(frame: .zero, textContainer: textContainer)
        textView.font = font
        textView.string = text
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.drawsBackground = false
        textView.textColor = .gray50
        textView.insertionPointColor = .labelColor
        
        // Create gutter
        let gutter = LineNumberGutter(scrollView: scrollView, textView: textView)
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.verticalRulerView = gutter
        
        // Setup text view with gutter space
        CodeEditor.updateTextViewInsets(textView: textView, gutterWidth: gutter.ruleThickness)
        
        // Handle gutter width changes
        gutter.onWidthChange = { [weak textView] width in
            guard let textView = textView else { return }
            CodeEditor.updateTextViewInsets(textView: textView, gutterWidth: width)
        }
        
        scrollView.documentView = textView
        
        // Store references
        context.coordinator.textView = textView
        context.coordinator.gutter = gutter
        
        // Setup scroll observation
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewDidScroll),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        
        if textView.string != text {
            textView.string = text
        }
        
        context.coordinator.gutter?.needsDisplay = true
    }
    
    private static func updateTextViewInsets(textView: NSTextView, gutterWidth: CGFloat) {
        let currentInset = textView.textContainerInset
        // ⬇️ ruler(gutter)는 스크롤뷰가 따로 너비를 빼주므로, 텍스트 인셋엔 고정 좌측 패딩만 둔다
        textView.textContainerInset = NSSize(
            width: 10,                 // ⬅️ 기존: gutterWidth + 12  (삭제)
            height: currentInset.height
        )
    }
}

// MARK: - Coordinator
extension CodeEditor {
    public class Coordinator: NSObject, NSTextViewDelegate {
        let parent: CodeEditor
        weak var textView: CodeTextView?
        weak var gutter: LineNumberGutter?
        
        init(_ parent: CodeEditor) {
            self.parent = parent
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            parent.text = textView.string
            
            // Ensure layout is updated
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            gutter?.needsDisplay = true
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            gutter?.needsDisplay = true
        }
        
        @objc func scrollViewDidScroll(_ notification: Notification) {
            gutter?.needsDisplay = true
        }
    }
}

// MARK: - Custom Text View
class CodeTextView: NSTextView {
    override var isOpaque: Bool { false }
    
    var currentLineRect: NSRect? {
        guard selectedRange.length == 0,
              let layoutManager = layoutManager,
              let textContainer = textContainer else { return nil }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: selectedRange.location)
        let lineRect = layoutManager.lineFragmentRect(
            forGlyphAt: glyphIndex,
            effectiveRange: nil
        )
        
        return NSRect(
            x: 0,
            y: lineRect.minY + textContainerOrigin.y,
            width: bounds.width,
            height: lineRect.height
        )
    }
    
    override func insertNewline(_ sender: Any?) {
        super.insertNewline(sender)
        
        // Force layout update
        layoutManager?.ensureLayout(for: textContainer!)
        needsDisplay = true
        
        // Update gutter
        if let gutter = enclosingScrollView?.verticalRulerView as? LineNumberGutter {
            gutter.needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw current line highlight
        if let lineRect = currentLineRect {
            NSColor.selectedTextBackgroundColor.withAlphaComponent(0.1).setFill()
            NSBezierPath(rect: lineRect).fill()
        }
    }
}

// MARK: - Line Number Gutter
class LineNumberGutter: NSRulerView {
    weak var textView: CodeTextView?
    var onWidthChange: ((CGFloat) -> Void)?
    
    private let padding: CGFloat = 8
    private let minWidth: CGFloat = 30
    
    init(scrollView: NSScrollView, textView: CodeTextView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = minWidth
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        // Draw gutter background
        NSColor.black100.setFill()
        NSBezierPath(rect: bounds).fill()
        
        // Get visible range
        let visibleRect = scrollView?.contentView.bounds ?? .zero
        let textVisibleRect = NSRect(
            x: visibleRect.minX - textView.textContainerOrigin.x,
            y: visibleRect.minY - textView.textContainerOrigin.y,
            width: visibleRect.width,
            height: visibleRect.height
        )
        
        let glyphRange = layoutManager.glyphRange(forBoundingRect: textVisibleRect, in: textContainer)
        guard glyphRange.length > 0 else { return }
        
        // Calculate required width
        let totalLines = lineCount(in: textView.string)
        let requiredWidth = calculateRequiredWidth(for: totalLines)
        
        if abs(ruleThickness - requiredWidth) > 1 {
            ruleThickness = requiredWidth
            onWidthChange?(requiredWidth)
        }
        
        // Draw current line highlight in gutter
        drawCurrentLineHighlight()
        
        // Draw line numbers
        drawLineNumbers(in: glyphRange, layoutManager: layoutManager)
    }
    
    private func calculateRequiredWidth(for lineCount: Int) -> CGFloat {
        let font = textView?.font ?? .monospacedSystemFont(ofSize: 12, weight: .regular)
        let digits = max(2, String(lineCount).count)
        let textWidth = CGFloat(digits) * (font.pointSize * 0.6)
        return max(minWidth, textWidth + padding * 2)
    }
    
    private func drawCurrentLineHighlight() {
        guard let textView = textView,
              let currentLineRect = textView.currentLineRect else { return }
        
        let scrollOffset = scrollView?.contentView.bounds.minY ?? 0
        let highlightRect = NSRect(
            x: 0,
            y: currentLineRect.minY - scrollOffset,
            width: bounds.width - 1,
            height: currentLineRect.height
        )
        
        NSColor.selectedTextBackgroundColor.withAlphaComponent(0.2).setFill()
        NSBezierPath(rect: highlightRect).fill()
    }
    
    private func drawLineNumbers(in glyphRange: NSRange, layoutManager: NSLayoutManager) {
        guard let textView = textView else { return }

        let font = textView.font ?? .monospacedSystemFont(ofSize: 12, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]

        let scrollOffsetY = scrollView?.contentView.bounds.minY ?? 0
        let lineHeight = layoutManager.defaultLineHeight(for: font)   // ⬅️ 줄 높이 기준

        var drawn = Set<Int>()

        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, usedRect, _, glyphRange, _ in
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            let ln = self.lineNumber(at: charIndex, in: textView.string)
            guard drawn.insert(ln).inserted else { return }

            // fragment의 실제 높이(rect.height) 안에서 "줄 높이"를 중앙 정렬
            let topYInTextView = rect.minY + textView.textContainerOrigin.y - scrollOffsetY
            let y = round(topYInTextView + (rect.height - lineHeight) / 2.0) // ⬅️ 픽셀 스냅

            let numberRect = NSRect(
                x: self.padding,
                y: y,
                width: self.bounds.width - self.padding * 2,
                height: lineHeight
            )

            NSAttributedString(string: "\(ln)", attributes: attributes).draw(in: numberRect)
        }

        // extra line fragment(문서 끝 빈 줄)
        let extraRect = layoutManager.extraLineFragmentRect
        if extraRect != .zero {
            let ln = lineCount(in: textView.string)
            let topYInTextView = extraRect.minY + textView.textContainerOrigin.y - scrollOffsetY
            let y = round(topYInTextView + (extraRect.height - lineHeight) / 2.0)

            let numberRect = NSRect(
                x: padding,
                y: y,
                width: bounds.width - padding * 2,
                height: lineHeight
            )

            NSAttributedString(string: "\(ln)", attributes: attributes).draw(in: numberRect)
        }
    }

    
    private func lineNumber(at charIndex: Int, in string: String) -> Int {
        let nsString = string as NSString
        let safeIndex = min(charIndex, nsString.length)
        
        var lineNumber = 1
        nsString.substring(to: safeIndex).forEach { char in
            if char == "\n" {
                lineNumber += 1
            }
        }
        
        return lineNumber
    }
    
    private func lineCount(in string: String) -> Int {
        guard !string.isEmpty else { return 1 }
        
        var count = 1
        for char in string {
            if char == "\n" {
                count += 1
            }
        }
        
        return count
    }
}

// MARK: - Preview
#if DEBUG
struct CodeEditor_Previews: PreviewProvider {
    static var previews: some View {
        CodeEditor(text: .constant("""
        import SwiftUI
        
        struct ContentView: View {
            @State private var code = "Hello, World!"
            
            var body: some View {
                VStack {
                    Text("Code Editor")
                        .font(.title)
                    
                    CodeEditor(text: $code)
                        .frame(minWidth: 400, minHeight: 300)
                        .border(Color.gray)
                }
                .padding()
            }
        }
        
        // This is a very long line that should wrap when the window is resized and the gutter should handle this gracefully without misaligning the line numbers
        """))
        .frame(width: 600, height: 400)
    }
}
#endif
