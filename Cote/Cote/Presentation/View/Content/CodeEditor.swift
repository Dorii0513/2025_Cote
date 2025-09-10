//
//  Editor.swift
//  Cote
//
//  Created by 김예림 on 8/10/25.
//


import SwiftUI
import AppKit
import Foundation

// MARK: - Configuration
public struct CodeEditorConfiguration {
    public let font: NSFont
    public let gutterWidth: CGFloat
    public let gutterPadding: CGFloat
    public let textInset: NSSize
    public let lineNumberFont: NSFont
    
    public static let defaultConfig = CodeEditorConfiguration(
        font: NSFont(name: "JetBrainsMono-Regular", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular),
        gutterWidth: 40,
        gutterPadding: 8,
        textInset: NSSize(width: 10, height: 8),
        lineNumberFont: .monospacedSystemFont(ofSize: 11, weight: .regular)
    )
    
    public init(
        font: NSFont,
        gutterWidth: CGFloat,
        gutterPadding: CGFloat,
        textInset: NSSize,
        lineNumberFont: NSFont
    ) {
        self.font = font
        self.gutterWidth = gutterWidth
        self.gutterPadding = gutterPadding
        self.textInset = textInset
        self.lineNumberFont = lineNumberFont
    }
}

// MARK: - SwiftUI Code Editor
public struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var suggestedTags: [String]
    @Binding var showSuggestedTags: Bool
    
    private let configuration: CodeEditorConfiguration
    
    // Primary initializer with configuration
    public init(
        text: Binding<String>,
        suggestedTags: Binding<[String]> = .constant([]),
        showSuggestedTags: Binding<Bool> = .constant(false),
        configuration: CodeEditorConfiguration
    ) {
        self._text = text
        self._suggestedTags = suggestedTags
        self._showSuggestedTags = showSuggestedTags
        self.configuration = configuration
    }
    
    // Convenience initializer with default configuration
    public init(
        text: Binding<String>,
        suggestedTags: Binding<[String]> = .constant([]),
        showSuggestedTags: Binding<Bool> = .constant(false)
    ) {
        self._text = text
        self._suggestedTags = suggestedTags
        self._showSuggestedTags = showSuggestedTags
        self.configuration = .defaultConfig
    }
    
    // Legacy initializer with custom font
    public init(
        text: Binding<String>,
        suggestedTags: Binding<[String]> = .constant([]),
        showSuggestedTags: Binding<Bool> = .constant(false),
        font: NSFont
    ) {
        self._text = text
        self._suggestedTags = suggestedTags
        self._showSuggestedTags = showSuggestedTags
        self.configuration = CodeEditorConfiguration(
            font: font,
            gutterWidth: CodeEditorConfiguration.defaultConfig.gutterWidth,
            gutterPadding: CodeEditorConfiguration.defaultConfig.gutterPadding,
            textInset: CodeEditorConfiguration.defaultConfig.textInset,
            lineNumberFont: CodeEditorConfiguration.defaultConfig.lineNumberFont
        )
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = createScrollView()
        let textView = createTextView(context: context)
        let gutter = LineNumberGutter(textView: textView, configuration: configuration)
        
        setupScrollView(scrollView, textView: textView, gutter: gutter, context: context)
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              textView.string != text else { return }
        
        textView.string = text
        context.coordinator.gutter?.needsDisplay = true
    }
    
    private func createScrollView() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        return scrollView
    }
    
    private func createTextView(context: Context) -> CodeTextView {
        let textSystem = TextSystemFactory.create()
        let textView = CodeTextView(frame: .zero, textContainer: textSystem.textContainer)
        
        configureTextView(textView, context: context)
        
        return textView
    }
    
    private func configureTextView(_ textView: CodeTextView, context: Context) {
        textView.font = configuration.font
        textView.string = text
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = configuration.textInset
        textView.drawsBackground = false
        textView.textColor = NSColor.labelColor
        textView.insertionPointColor = .labelColor
        textView.typingAttributes[.font] = configuration.font
    }
    
    private func setupScrollView(_ scrollView: NSScrollView, textView: CodeTextView, gutter: LineNumberGutter, context: Context) {
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.verticalRulerView = gutter
        scrollView.documentView = textView
        
        context.coordinator.configure(textView: textView, gutter: gutter, scrollView: scrollView)
    }
}

// MARK: - Text System Factory
private struct TextSystemFactory {
    struct TextSystem {
        let textStorage: NSTextStorage
        let layoutManager: NSLayoutManager
        let textContainer: NSTextContainer
    }
    
    static func create() -> TextSystem {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        
        return TextSystem(
            textStorage: textStorage,
            layoutManager: layoutManager,
            textContainer: textContainer
        )
    }
}

// MARK: - Coordinator
extension CodeEditor {
    public class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: CodeEditor
        private weak var scrollView: NSScrollView?
        
        weak var textView: CodeTextView?
        weak var gutter: LineNumberGutter?
        
        init(_ parent: CodeEditor) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func configure(textView: CodeTextView, gutter: LineNumberGutter, scrollView: NSScrollView) {
            self.textView = textView
            self.gutter = gutter
            self.scrollView = scrollView
            
            setupScrollObserver(scrollView)
        }
        
        private func setupScrollObserver(_ scrollView: NSScrollView) {
            scrollView.contentView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(scrollViewDidScroll),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        }
        
        // MARK: - Text View Delegate
        public func textView(_ textView: NSTextView,
                             shouldChangeTextIn affectedCharRange: NSRange,
                             replacementString: String?) -> Bool {
            
            if NewlineDetector.isNewline(replacementString) {
                scheduleGutterUpdate()
            }
            return true
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            parent.text = textView.string
            updateLayoutAndGutter()
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            gutter?.needsDisplay = true
        }
        
        @objc func scrollViewDidScroll(_ notification: Notification) {
            gutter?.needsDisplay = true
        }
        
        // MARK: - Private Methods
        private func scheduleGutterUpdate() {
            DispatchQueue.main.async { [weak self] in
                self?.updateLayoutAndGutter()
            }
        }
        
        private func updateLayoutAndGutter() {
            guard let textView = textView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }
            
            let textLength = (textView.string as NSString).length
            layoutManager.ensureGlyphs(forCharacterRange: NSRange(location: 0, length: textLength))
            layoutManager.ensureLayout(for: textContainer)
            
            gutter?.invalidateHashMarks()
            gutter?.needsDisplay = true
        }
    }
}

// MARK: - Newline Detection Utility
private struct NewlineDetector {
    static func isNewline(_ string: String?) -> Bool {
        return string == "\n" || string == "\r"
    }
}

// MARK: - Custom Text View
class CodeTextView: NSTextView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async {
            self.window?.makeFirstResponder(nil) // 자동 포커스 제거
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        CurrentLineHighlighter.draw(in: self)
    }
}

// MARK: - Current Line Highlighter
private struct CurrentLineHighlighter {
    static func draw(in textView: CodeTextView) {
        guard let lineRect = getCurrentLineRect(in: textView) else { return }
        
        NSColor.selectedTextBackgroundColor.withAlphaComponent(0.1).setFill()
        NSBezierPath(rect: lineRect).fill()
    }
    
    private static func getCurrentLineRect(in textView: CodeTextView) -> NSRect? {
        guard textView.selectedRange.length == 0,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return nil }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: textView.selectedRange.location)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        
        return NSRect(
            x: 0,
            y: lineRect.minY + textView.textContainerOrigin.y,
            width: textView.bounds.width,
            height: lineRect.height
        )
    }
}

// MARK: - Line Number Gutter
class LineNumberGutter: NSRulerView {
    private weak var textView: CodeTextView?
    private let configuration: CodeEditorConfiguration

    init(textView: CodeTextView, configuration: CodeEditorConfiguration) {
        self.textView = textView
        self.configuration = configuration
        super.init(scrollView: nil, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = configuration.gutterWidth
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 분리선 그리는 기본 드로잉을 막는다
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        drawHashMarksAndLabels(in: dirtyRect)
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        ensureCorrectWidth()

        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        GutterRenderer.render(
            in: self,
            textView: textView,
            layoutManager: layoutManager,
            textContainer: textContainer,
            configuration: configuration
        )
    }

    private func ensureCorrectWidth() {
        if ruleThickness != configuration.gutterWidth {
            ruleThickness = configuration.gutterWidth
        }
    }
}

// MARK: - Gutter Renderer
private struct GutterRenderer {
    static func render(
        in gutter: LineNumberGutter,
        textView: CodeTextView,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        configuration: CodeEditorConfiguration
    ) {
        drawBackground(in: gutter)
        drawCurrentLineHighlight(in: gutter, textView: textView, layoutManager: layoutManager)
        
        let visibleGlyphRange = getVisibleGlyphRange(gutter: gutter, layoutManager: layoutManager, textContainer: textContainer)
        guard visibleGlyphRange.length > 0 else { return }
        
        drawLineNumbers(
            in: gutter,
            textView: textView,
            layoutManager: layoutManager,
            glyphRange: visibleGlyphRange,
            configuration: configuration
        )
    }
    
    private static func drawBackground(in gutter: LineNumberGutter) {
        NSColor.black200.setFill()
        NSBezierPath(rect: gutter.bounds).fill()
        
    }
    
    private static func drawCurrentLineHighlight(
        in gutter: LineNumberGutter,
        textView: CodeTextView,
        layoutManager: NSLayoutManager
    ) {
        guard let scrollView = gutter.scrollView,
              textView.selectedRange.length == 0 else { return }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: textView.selectedRange.location)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        
        let scrollOffset = scrollView.contentView.bounds.minY
        let highlightRect = NSRect(
            x: 0,
            y: lineRect.minY + textView.textContainerOrigin.y - scrollOffset,
            width: gutter.bounds.width,
            height: lineRect.height
        )
        
        NSColor.selectedTextBackgroundColor.withAlphaComponent(0.2).setFill()
        NSBezierPath(rect: highlightRect).fill()
    }
    
    private static func getVisibleGlyphRange(
        gutter: LineNumberGutter,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer
    ) -> NSRange {
        guard let scrollView = gutter.scrollView else { return NSRange() }
        let visibleRect = scrollView.contentView.bounds
        return layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
    }
    
    private static func drawLineNumbers(
        in gutter: LineNumberGutter,
        textView: CodeTextView,
        layoutManager: NSLayoutManager,
        glyphRange: NSRange,
        configuration: CodeEditorConfiguration
    ) {
        guard let scrollView = gutter.scrollView else { return }
        
        let lineNumberRenderer = LineNumberRenderer(
            font: configuration.lineNumberFont,
            padding: configuration.gutterPadding,
            gutterWidth: gutter.bounds.width
        )
        
        let scrollOffset = scrollView.contentView.bounds.minY
        var drawnLines = Set<Int>()
        
        // Draw line numbers for visible fragments
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, _, _, glyphRange, _ in
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            let lineNumber = LineNumberCalculator.lineNumber(at: charIndex, in: textView.string)
            
            guard drawnLines.insert(lineNumber).inserted else { return }
            
            lineNumberRenderer.drawLineNumber(
                lineNumber,
                at: rect.minY + textView.textContainerOrigin.y - scrollOffset,
                lineHeight: rect.height
            )
        }
        
        // Draw current line number if not already drawn (for empty lines)
        drawCurrentLineNumberIfNeeded(
            textView: textView,
            layoutManager: layoutManager,
            scrollOffset: scrollOffset,
            drawnLines: drawnLines,
            renderer: lineNumberRenderer
        )
    }
    
    private static func drawCurrentLineNumberIfNeeded(
        textView: CodeTextView,
        layoutManager: NSLayoutManager,
        scrollOffset: CGFloat,
        drawnLines: Set<Int>,
        renderer: LineNumberRenderer
    ) {
        let caretLine = LineNumberCalculator.lineNumber(at: textView.selectedRange.location, in: textView.string)
        
        guard !drawnLines.contains(caretLine) else { return }
        
        let caretGlyphIndex = layoutManager.glyphIndexForCharacter(at: textView.selectedRange.location)
        let caretRect = layoutManager.lineFragmentRect(forGlyphAt: caretGlyphIndex, effectiveRange: nil)
        let y = caretRect.minY + textView.textContainerOrigin.y - scrollOffset
        
        renderer.drawLineNumber(caretLine, at: y, lineHeight: caretRect.height)
    }
}

// MARK: - Line Number Calculator
private struct LineNumberCalculator {
    static func lineNumber(at index: Int, in string: String) -> Int {
        let safeIndex = min(index, string.count)
        return string.prefix(safeIndex).reduce(1) { count, char in
            char == "\n" ? count + 1 : count
        }
    }
}

// MARK: - Line Number Renderer
private struct LineNumberRenderer {
    private let attributes: [NSAttributedString.Key: Any]
    private let padding: CGFloat
    private let gutterWidth: CGFloat
    private let lineHeight: CGFloat
    
    init(font: NSFont, padding: CGFloat, gutterWidth: CGFloat) {
        self.padding = padding
        self.gutterWidth = gutterWidth
        self.lineHeight = font.pointSize
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        
        self.attributes = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    func drawLineNumber(_ lineNumber: Int, at y: CGFloat, lineHeight: CGFloat) {
        let adjustedY = y + (lineHeight - self.lineHeight) / 2
        let numberRect = NSRect(
            x: padding,
            y: adjustedY,
            width: gutterWidth - padding * 2,
            height: self.lineHeight
        )
        
        NSAttributedString(string: "\(lineNumber)", attributes: attributes).draw(in: numberRect)
    }
}
