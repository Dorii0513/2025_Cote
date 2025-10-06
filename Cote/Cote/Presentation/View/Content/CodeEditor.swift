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
        gutterWidth: 35,
        gutterPadding: 8,
        textInset: NSSize(width: 10, height: 8),
        lineNumberFont: NSFont(name: "JetBrainsMono-Regular", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular),    )
    
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
    private let configuration: CodeEditorConfiguration
    
    // Primary initializer with configuration
    public init(
        text: Binding<String>,
        configuration: CodeEditorConfiguration = .defaultConfig
    ) {
        self._text = text
        self.configuration = configuration
    }
    
    // Legacy initializer with custom font
    public init(
        text: Binding<String>,
        font: NSFont
    ) {
        self.init(
            text: text,
            configuration: CodeEditorConfiguration(
                font: font,
                gutterWidth: CodeEditorConfiguration.defaultConfig.gutterWidth,
                gutterPadding: CodeEditorConfiguration.defaultConfig.gutterPadding,
                textInset: CodeEditorConfiguration.defaultConfig.textInset,
                lineNumberFont: CodeEditorConfiguration.defaultConfig.lineNumberFont
            )
        )
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ScrollViewFactory.create()
        let textView = TextViewFactory.create(configuration: configuration, coordinator: context.coordinator)
        let gutter = LineNumberGutter(textView: textView, configuration: configuration)
        
        ScrollViewFactory.setup(scrollView, textView: textView, gutter: gutter, coordinator: context.coordinator)
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              textView.string != text else { return }
        
        textView.string = text
        context.coordinator.scheduleGutterRedraw()
    }
}

// MARK: - Factory Methods
private enum ScrollViewFactory {
    static func create() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        return scrollView
    }
    
    static func setup(_ scrollView: NSScrollView, textView: CodeTextView, gutter: LineNumberGutter, coordinator: CodeEditor.Coordinator) {
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.verticalRulerView = gutter
        scrollView.documentView = textView
        
        coordinator.configure(textView: textView, gutter: gutter, scrollView: scrollView)
    }
}

private enum TextViewFactory {
    static func create(configuration: CodeEditorConfiguration, coordinator: CodeEditor.Coordinator) -> CodeTextView {
        let textSystem = TextSystemFactory.create()
        let textView = CodeTextView(frame: .zero, textContainer: textSystem.textContainer)
        
        configure(textView, with: configuration, coordinator: coordinator)
        
        return textView
    }
    
    private static func configure(_ textView: CodeTextView, with config: CodeEditorConfiguration, coordinator: CodeEditor.Coordinator) {
        textView.font = config.font
        textView.delegate = coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = config.textInset
        textView.drawsBackground = false
        textView.textColor = .labelColor
        textView.insertionPointColor = .labelColor
        textView.typingAttributes[.font] = config.font
        textView.isRichText = false         // 서식 비활성화
        textView.importsGraphics = false    // 이미지 첨부 금지
        textView.usesRuler = false
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        
        // 2) 이후 타이핑되는 텍스트에도 동일하게 적용
        textView.defaultParagraphStyle = style
        textView.typingAttributes[.paragraphStyle] = style
        
        // 3) 기존 텍스트 전체에도 적용
        if let storage = textView.textStorage {
            storage.beginEditing()
            storage.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: storage.length))
            storage.endEditing()
        }
        
        // 4) 레이아웃 강제 갱신 + 다시 그리기
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        textView.needsDisplay = true
    }
}

private enum TextSystemFactory {
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
        
        private var gutterRedrawScheduled = false
        
        init(_ parent: CodeEditor) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func scheduleGutterRedraw() {
            guard !gutterRedrawScheduled else { return }
            gutterRedrawScheduled = true
            DispatchQueue.main.async { [weak self] in
                self?.gutter?.needsDisplay = true
                self?.gutterRedrawScheduled = false
            }
        }
        
        func configure(textView: CodeTextView, gutter: LineNumberGutter, scrollView: NSScrollView) {
            self.textView = textView
            self.gutter = gutter
            self.scrollView = scrollView
            textView.string = parent.text
            textView.postsFrameChangedNotifications = true
            
            setupScrollObserver(scrollView)
            setupLayoutObserver(textView)
            
            // 텍스트뷰 프레임 변경에도 리렌더
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textViewFrameDidChange),
                name: NSView.frameDidChangeNotification,
                object: textView
            )
        }
        
        @objc private func textViewFrameDidChange(_ n: Notification) {
            // 폭 변경 → 레이아웃 강제 확인 + gutter 리드로우
            textView?.layoutManager?.ensureLayout(for: textView!.textContainer!)
            scheduleGutterRedraw()
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
        
        private func setupLayoutObserver(_ textView: NSTextView) {
            guard let layoutManager = textView.layoutManager else { return }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(layoutManagerDidCompleteLayout),
                name: NSTextStorage.didProcessEditingNotification,
                object: layoutManager.textStorage
            )
        }
        
        // MARK: - Text View Delegate
        public func textView(_ textView: NSTextView,
                             shouldChangeTextIn affectedCharRange: NSRange,
                             replacementString: String?) -> Bool {
            return true
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            parent.text = textView.string
            scheduleGutterRedraw()
        }
        
        @objc func layoutManagerDidCompleteLayout(_ notification: Notification) {
            scheduleGutterRedraw()
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            scheduleGutterRedraw()
        }
        
        @objc func scrollViewDidScroll(_ notification: Notification) {
            scheduleGutterRedraw()
        }
    }
}


// MARK: - String Extension
private extension String {
    func lineNumber(at index: Int) -> Int {
        let safeIndex = min(index, count)
        return prefix(safeIndex).reduce(1) { $1 == "\n" ? $0 + 1 : $0 }
    }
}

// MARK: - Custom Text View
class CodeTextView: NSTextView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(nil)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawCurrentLineHighlight()
    }
    
    private func drawCurrentLineHighlight() {
        guard selectedRange.length == 0,
              let layoutManager = layoutManager,
              let textContainer = textContainer else { return }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: selectedRange.location)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        
        let highlightRect = NSRect(
            x: 0,
            y: lineRect.minY + textContainerOrigin.y,
            width: bounds.width,
            height: lineRect.height
        )
        
        NSColor.selectedTextBackgroundColor.withAlphaComponent(0.1).setFill()
        NSBezierPath(rect: highlightRect).fill()
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
    
    override var isOpaque: Bool { false }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              let scrollView = scrollView else { return }
        
        
        GutterRenderer.render(
            in: self,
            textView: textView,
            layoutManager: layoutManager,
            textContainer: textContainer,
            scrollView: scrollView,
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
private enum GutterRenderer {
    static func render(
        in gutter: LineNumberGutter,
        textView: CodeTextView,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        scrollView: NSScrollView,
        configuration: CodeEditorConfiguration
    ) {
        drawBackground(in: gutter)
        
        // glyphRange는 텍스트가 입력될 수 있는 한 글자씩의 단위들이 모여 이루는 하나의 범위를 말 함.
        let visibleGlyphRange = layoutManager.glyphRange(
            forBoundingRect: scrollView.contentView.bounds,
            in: textContainer
        )
        guard visibleGlyphRange.length > 0 else { return }
        
        drawLineNumbers(
            in: gutter,
            textView: textView,
            layoutManager: layoutManager,
            scrollView: scrollView,
            glyphRange: visibleGlyphRange,
            configuration: configuration
        )
    }
    
    
    private static func drawBackground(in gutter: LineNumberGutter) {
        NSColor.black200.setFill()
        NSBezierPath(rect: gutter.bounds).fill()
    }
    
    private static func drawLineNumbers(
        in gutter: LineNumberGutter,
        textView: CodeTextView,
        layoutManager: NSLayoutManager,
        scrollView: NSScrollView,
        glyphRange: NSRange,
        configuration: CodeEditorConfiguration
    ) {
        let renderer = LineNumberRenderer(
            font: configuration.lineNumberFont,
            padding: configuration.gutterPadding,
            gutterWidth: gutter.bounds.width
        )
        
        let scrollOffset = scrollView.contentView.bounds.minY
        var drawnLines = Set<Int>()
        
        // glyphRange를 한 줄씩 순회
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, usedRect, _, glyphRange, _ in
            // 해당 줄의 첫 번째 글자의 index 알아내기
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            // 해당 줄의 첫번 째 글자(charIndex)가 몇 번째 줄에 있는지
            let lineNumber = textView.string.lineNumber(at: charIndex)
            
            guard drawnLines.insert(lineNumber).inserted else { return }
            
            let actualHeight = usedRect.height > 0 ? usedRect.height : rect.height
            let yPosition = rect.minY + textView.textContainerOrigin.y - scrollOffset
            
            renderer.drawLineNumber(
                lineNumber,
                at: yPosition,
                lineHeight: actualHeight
            )
        }
        
        drawCurrentLineNumberIfNeeded(
            textView: textView,
            layoutManager: layoutManager,
            scrollOffset: scrollOffset,
            drawnLines: drawnLines,
            renderer: renderer
        )
    }
    
    private static func drawCurrentLineNumberIfNeeded(
        textView: CodeTextView,
        layoutManager: NSLayoutManager,
        scrollOffset: CGFloat,
        drawnLines: Set<Int>,
        renderer: LineNumberRenderer
    ) {
        let caretLocation = textView.selectedRange.location
        let caretLine = textView.string.lineNumber(at: caretLocation)
        guard !drawnLines.contains(caretLine) else { return }
        
        let caretGlyphIndex = layoutManager.glyphIndexForCharacter(at: caretLocation)
        
        let caretRect: NSRect
        if caretGlyphIndex < layoutManager.numberOfGlyphs {
            caretRect = layoutManager.lineFragmentRect(forGlyphAt: caretGlyphIndex, effectiveRange: nil)
        } else {
            caretRect = layoutManager.extraLineFragmentRect
        }
        
        let y = caretRect.minY + textView.textContainerOrigin.y - scrollOffset
        renderer.drawLineNumber(caretLine, at: y, lineHeight: caretRect.height)
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
            y: max(0, adjustedY), // 음수 방지
            width: gutterWidth - padding * 2,
            height: self.lineHeight
        )
        
        NSAttributedString(string: "\(lineNumber)", attributes: attributes).draw(in: numberRect)
    }
}

