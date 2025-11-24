//
//  Editor.swift
//  Cote
//
//  Created by 김예림 on 8/10/25.
//

import SwiftUI
import AppKit
import Highlightr

// MARK: - Configuration
public struct CodeEditorConfiguration {
    public let font: NSFont
    public let gutterWidth: CGFloat
    public let gutterPadding: CGFloat
    public let textInset: NSEdgeInsets
    public let lineNumberFont: NSFont
    public let theme: String
    
    
    public static let defaultConfig = CodeEditorConfiguration(
        font: NSFont(name: "JetBrainsMono-Medium", size: 12) ?? .monospacedSystemFont(ofSize: 13, weight: .regular),
        gutterWidth: 35,
        gutterPadding: 8,
        textInset: NSEdgeInsets(top: 40, left: 10, bottom: 0, right: 10),
        lineNumberFont: NSFont(name: "JetBrainsMono-Regular", size: 12) ?? .monospacedSystemFont(ofSize: 12, weight: .regular),
        theme: "paraiso-dark"
    )
    
    public init(
        font: NSFont,
        gutterWidth: CGFloat,
        gutterPadding: CGFloat,
        textInset: NSEdgeInsets,
        lineNumberFont: NSFont,
        theme: String
    ) {
        self.font = font
        self.gutterWidth = gutterWidth
        self.gutterPadding = gutterPadding
        self.textInset = textInset
        self.lineNumberFont = lineNumberFont
        self.theme = theme
    }
}

// MARK: - SwiftUI Code Editor
public struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var language: String
    @Binding var aiComments: [AIComment]
    private let configuration: CodeEditorConfiguration
    
    public init(
        text: Binding<String>,
        language: Binding<String>,
        configuration: CodeEditorConfiguration = .defaultConfig
    ) {
        self._text = text
        self._language = language
        self._aiComments = .constant([])
        self.configuration = configuration
    }
    
    init(
        text: Binding<String>,
        language: Binding<String>,
        aiComments: Binding<[AIComment]>,
        configuration: CodeEditorConfiguration = .defaultConfig
    ) {
        self._text = text
        self._language = language
        self._aiComments = aiComments
        self.configuration = configuration
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ScrollViewFactory.create()
        let textView = TextViewFactory.create(configuration: configuration, coordinator: context.coordinator, language: language)
        let gutter = LineNumberGutter(textView: textView, configuration: configuration)
        
        ScrollViewFactory.setup(scrollView, textView: textView, gutter: gutter, coordinator: context.coordinator)
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        
        // 언어 변경
        if let storage = textView.textStorage as? CodeAttributedString, storage.language != language {
            storage.beginEditing()
            storage.language = language
            storage.endEditing()
            
            if let lm = textView.layoutManager, let tc = textView.textContainer {
                lm.ensureLayout(for: tc)
            }
            
            textView.setNeedsDisplay(textView.bounds)
            context.coordinator.gutter?.needsDisplay = true
        }
        
        // 텍스트 내용 변경
        if textView.string != text {
            textView.string = text
        }
        
        context.coordinator.updateComments(aiComments)
        context.coordinator.scheduleGutterRedraw()
    }

}

// MARK: - Factory Methods
private enum ScrollViewFactory {
    static func create() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.verticalScrollElasticity = .automatic
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = false
        return scrollView
    }
    
    static func setup(_ scrollView: NSScrollView, textView: CodeTextView, gutter: LineNumberGutter, coordinator: CodeEditor.Coordinator) {
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.verticalRulerView = gutter
        scrollView.documentView = textView
        
        // 잘림 방지: 크기 자동 조정
        scrollView.contentView.autoresizingMask = [.width, .height]
        scrollView.autoresizesSubviews = true
        
        coordinator.configure(textView: textView, gutter: gutter, scrollView: scrollView)
    }
}

private enum TextViewFactory {
    static func create(configuration: CodeEditorConfiguration, coordinator: CodeEditor.Coordinator, language: String) -> CodeTextView {
        let textSystem = TextSystemFactory.create(language: language)
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
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        let horizontalInset = config.textInset.left + config.textInset.right
        let verticalInset = config.textInset.top + config.textInset.bottom
        textView.textContainerInset = NSSize(width: horizontalInset / 2, height: verticalInset / 2)
        
        textView.drawsBackground = false
        textView.textColor = .gray80    // codeColor
        textView.insertionPointColor = .gray50
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
        
        // 레이아웃/컨테이너 크기: 수직 무한 + 너비는 뷰에 추적
        if let lm = textView.layoutManager, let tc = textView.textContainer {
            tc.widthTracksTextView = true
            tc.heightTracksTextView = false
            tc.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            lm.ensureLayout(for: tc)
        }
    }
}


private enum TextSystemFactory {
    struct TextSystem {
        let textStorage: NSTextStorage
        let layoutManager: NSLayoutManager
        let textContainer: NSTextContainer
    }
    
    static func create(language: String) -> TextSystem {
        
        // syntaxHighligt
        let textStorage = CodeAttributedString()
        
        textStorage.language = language
        textStorage.highlightr.setTheme(to: "atom-one-dark")
        //atom-one-dark
        
        
        // 폰트 재적용
        textStorage.highlightr.theme.codeFont = NSFont(name: "JetBrainsMono-Medium", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        
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
            textContainer: textContainer,
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
        
        // 주석 생성
        func updateComments(_ comments: [AIComment]) {
            let lines = Set(comments.map { $0.line })
            gutter?.commentLines = lines
            gutter?.needsDisplay = true
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
    }
}

// MARK: - Line Number Gutter
class LineNumberGutter: NSRulerView {
    private weak var textView: CodeTextView?
    private let configuration: CodeEditorConfiguration
    var commentLines: Set<Int> = []
    
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
            configuration: configuration,
            commentLines: commentLines
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
        configuration: CodeEditorConfiguration,
        commentLines: Set<Int>
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
            configuration: configuration,
            commentLines: commentLines
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
        configuration: CodeEditorConfiguration,
        commentLines: Set<Int>
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
            .foregroundColor: NSColor.black70,  // gutterColor
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

