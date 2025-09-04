//
//  Editor.swift
//  Cote
//
//  Created by 김예림 on 8/10/25.
//


//TODO: - 주석 삭제

import SwiftUI
import AppKit
import Foundation
//import NaturalLanguage
//import SystemConfiguration

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
    override var isOpaque: Bool { return false }
    
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
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath(rect: gutter.bounds).fill()
        
        // Separator line
        NSColor.separatorColor.setStroke()
        let separatorPath = NSBezierPath()
        separatorPath.move(to: NSPoint(x: gutter.bounds.maxX - 0.5, y: gutter.bounds.minY))
        separatorPath.line(to: NSPoint(x: gutter.bounds.maxX - 0.5, y: gutter.bounds.maxY))
        separatorPath.lineWidth = 1.0
        separatorPath.stroke()
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

// MARK: - Tag Generator
class TagGenerator {
    private let apiService: OpenAIService
    
    init(apiService: OpenAIService = OpenAIService()) {
        self.apiService = apiService
    }
    
    func generateTags(for code: String) async throws -> [String] {
        let prompt = TagPromptBuilder.buildPrompt()
        let response = try await apiService.generateCompletion(systemPrompt: prompt, userContent: code)
        return TagParser.parseTags(from: response)
    }
}

// MARK: - Tag Prompt Builder
private struct TagPromptBuilder {
    static func buildPrompt() -> String {
        return """
        You are a tagging assistant.  
        Generate up to 5 short, specific tags for the given text (code or notes).  
        
        Rules:  
        - Tags must be concise: prefer single words if possible.  
        - Use hyphen only if two words are truly needed.  
        - Do NOT include generic tags like "swift", "programming", "code", "notes".  
        - For code: describe purpose/feature (e.g., "gutter","highlight","pdf-annotation").  
        - For notes: describe the main topic (e.g., "meeting","error","design-feedback").  
        - Output only a pure JSON array of strings.  
        """
    }
}

// MARK: - Tag
private struct TagParser {
    static func parseTags(from text: String) -> [String] {
        // Try strict JSON parsing first
        if let jsonTags = parseAsJSON(text) {
            return Array(jsonTags.prefix(8))
        }
        
        // Fallback to comma-separated parsing
        return parseAsCommaSeparated(text)
    }
    
    private static func parseAsJSON(_ text: String) -> [String]? {
        guard let start = text.firstIndex(of: "["),
              let end = text.lastIndex(of: "]") else { return nil }
        
        let jsonSlice = String(text[start...end])
        guard let data = jsonSlice.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [String] else { return nil }
        
        return array
    }
    
    private static func parseAsCommaSeparated(_ text: String) -> [String] {
        return text
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Preview Container
#if DEBUG
struct CodeEditorPreviewContainer: View {
    
    // 텍스트 주입
    @State private var code: String = """
import PDFKit

class PDFAnnotationHandler {
    private var pdfView: PDFView
    
    init(view: PDFView) {
        self.pdfView = view
    }
    
    func addUnderline(to selection: PDFSelection) {
        let underline = PDFAnnotation(bounds: selection.bounds(for: pdfView.currentPage!),
                                      forType: .underline,
                                      withProperties: nil)
        pdfView.currentPage?.addAnnotation(underline)
    }
}
"""
    @State private var tags: [String] = []
    @State private var showTags: Bool = false
    @State private var isGeneratingTags: Bool = false
    
    private let tagGenerator = TagGenerator()
    
    var body: some View {
        VStack(spacing: 12) {
            //headerView
            codeEditorView
            if showTags {
                tagSectionView
            }
        }
    }
    
//    private var headerView: some View {
//        HStack {
//            Text("Code Editor")
//                .font(.headline)
//            
//            Spacer()
//            
//            tagToggleButton
//        }
//        .padding(.horizontal)
//    }
    
    private var tagToggleButton: some View {
        Button(action: toggleTags) {
            HStack(spacing: 6) {
                Image(systemName: showTags ? "tag.fill" : "tag")
                Text(showTags ? "Hide Tags" : "Show Tags")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(showTags ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(showTags ? .white : .primary)
            .cornerRadius(8)
        }
        .disabled(isGeneratingTags)
    }
    
    private var codeEditorView: some View {
        CodeEditor(text: $code, suggestedTags: $tags, showSuggestedTags: $showTags)
            .frame(minWidth: 400, minHeight: 300)
            .border(Color.gray)

    }
    
    private var tagSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            tagSectionHeader
            if !tags.isEmpty {
                tagChipsView
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var tagSectionHeader: some View {
        HStack {
            Text("Suggested Tags:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(isGeneratingTags ? "Generating..." : "Refresh", action: generateTags)
                .font(.caption)
                .foregroundColor(.blue)
                .disabled(isGeneratingTags)
        }
    }
    
    private var tagChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(tag: tag) {
                        insertTag(tag)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Actions
    private func toggleTags() {
        showTags.toggle()
        if showTags {
            generateTags()
        } else {
            tags = []
        }
    }
    
    private func generateTags() {
        guard !isGeneratingTags else { return }
        
        isGeneratingTags = true
        
        Task {
            do {
                let generatedTags = try await tagGenerator.generateTags(for: code)
                await MainActor.run {
                    self.tags = generatedTags
                    self.isGeneratingTags = false
                }
            } catch {
                await MainActor.run {
                    print("Failed to generate tags: \(error)")
                    self.isGeneratingTags = false
                }
            }
        }
    }
    
    private func insertTag(_ tag: String) {
        let insertion = "// #\(tag)\n"
        code += insertion
    }
}

// MARK: - Tag Chip View
private struct TagChip: View {
    let tag: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct CodeEditor_Previews: PreviewProvider {
    static var previews: some View {
        CodeEditorPreviewContainer()
            .frame(width: 600, height: 420)
    }
}

#endif
