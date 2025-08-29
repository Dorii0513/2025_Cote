//
//  Editor.swift
//  Cote
//
//  Created by 김예림 on 8/10/25.
//

import SwiftUI
import AppKit
import Foundation
import NaturalLanguage
import SystemConfiguration

// MARK: - SwiftUI Code Editor
public struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var suggestedTags: [String]
    @Binding var showSuggestedTags: Bool
    let font: NSFont
    
    public init(
        text: Binding<String>,
        suggestedTags: Binding<[String]> = .constant([]),
        showSuggestedTags: Binding<Bool> = .constant(false),
        font: NSFont = NSFont(name: "JetBrainsMono-Regular", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular)
    ) {
        self._text = text
        self._suggestedTags = suggestedTags
        self._showSuggestedTags = showSuggestedTags
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
        
        let textView = createTextView(context: context)
        let gutter = LineNumberGutter(textView: textView)
        
        setupScrollView(scrollView, textView: textView, gutter: gutter, context: context)
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              textView.string != text else { return }
        
        textView.string = text
        context.coordinator.gutter?.needsDisplay = true
    }
    
    private func createTextView(context: Context) -> CodeTextView {
        // Create text system
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textContainer.lineFragmentPadding = 0
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
        textView.textColor = NSColor.labelColor
        textView.insertionPointColor = .labelColor
        
        // 타이핑 속성에도 폰트 고정(안하면 입력 시 기본 폰트로 바뀌는 경우 있음)
        textView.typingAttributes[.font] = font
        
        return textView
    }
    
    private func setupScrollView(_ scrollView: NSScrollView, textView: CodeTextView, gutter: LineNumberGutter, context: Context) {
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.verticalRulerView = gutter
        scrollView.documentView = textView
        
        context.coordinator.textView = textView
        context.coordinator.gutter = gutter
        
        // Setup text view insets for gutter space (고정 좌측 패딩)
        updateTextViewInsets(textView: textView, gutterWidth: gutter.ruleThickness)
        
        // Scroll observation
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewDidScroll),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }
    
    private func updateTextViewInsets(textView: NSTextView, gutterWidth: CGFloat) {
        let currentInset = textView.textContainerInset
        textView.textContainerInset = NSSize(
            width: 10, // 고정 좌측 패딩 유지
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
        
        deinit {
            // Clean up observer to prevent crashes
            NotificationCenter.default.removeObserver(self)
        }

        // ✅ Enter 직후 거터 즉시 갱신
        public func textView(_ textView: NSTextView,
                             shouldChangeTextIn affectedCharRange: NSRange,
                             replacementString: String?) -> Bool {
            // 개행 입력을 감지하고, 실제 텍스트 반영 직후(다음 런루프)에 거터를 갱신한다
            if replacementString == "\n" || replacementString == "\r" {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let tv = self.textView, let lm = tv.layoutManager, let tc = tv.textContainer else { return }
                    // 글리프/레이아웃을 강제 생성해 빈 줄도 즉시 라인 프래그먼트가 생기도록 함
                    let len = (tv.string as NSString).length
                    lm.ensureGlyphs(forCharacterRange: NSRange(location: 0, length: len))
                    lm.ensureLayout(for: tc)
                    self.gutter?.invalidateHashMarks()
                    self.gutter?.needsDisplay = true
                }
            }
            return true
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            parent.text = textView.string
            
            // Ensure layout is updated
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            gutter?.invalidateHashMarks()
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
    
    private var currentLineRect: NSRect? {
        guard selectedRange.length == 0,
              let layoutManager = layoutManager,
              let textContainer = textContainer else { return nil }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: selectedRange.location)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        
        return NSRect(
            x: 0,
            y: lineRect.minY + textContainerOrigin.y,
            width: bounds.width,
            height: lineRect.height
        )
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawCurrentLineHighlight()
    }
    
    private func drawCurrentLineHighlight() {
        guard let lineRect = currentLineRect else { return }
        NSColor.selectedTextBackgroundColor.withAlphaComponent(0.1).setFill()
        NSBezierPath(rect: lineRect).fill()
    }
}


// MARK: - Line Number Gutter
class LineNumberGutter: NSRulerView {
    private weak var textView: CodeTextView?
    private let padding: CGFloat = 8
    private let fixedWidth: CGFloat = 40   // Increased for better visibility
    
    init(textView: CodeTextView) {
        self.textView = textView
        super.init(scrollView: nil, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = fixedWidth
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        // ✅ 혹시 외부에서 바뀌었으면 즉시 되돌림
        if ruleThickness != fixedWidth {
            ruleThickness = fixedWidth
        }
        
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        drawBackground()
        drawCurrentLineHighlight()
        
        let visibleGlyphRange = getVisibleGlyphRange(layoutManager: layoutManager, textContainer: textContainer)
        guard visibleGlyphRange.length > 0 else { return }
        
        drawLineNumbers(glyphRange: visibleGlyphRange, layoutManager: layoutManager)
    }
    
    private func drawBackground() {
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath(rect: bounds).fill()
        
        // Add separator line
        NSColor.separatorColor.setStroke()
        let separatorPath = NSBezierPath()
        separatorPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY))
        separatorPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
        separatorPath.lineWidth = 1.0
        separatorPath.stroke()
    }
    
    private func drawCurrentLineHighlight() {
        guard let textView = textView,
              let scrollView = scrollView,
              textView.selectedRange.length == 0,
              let layoutManager = textView.layoutManager else { return }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: textView.selectedRange.location)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        
        let scrollOffset = scrollView.contentView.bounds.minY
        let highlightRect = NSRect(
            x: 0,
            y: lineRect.minY + textView.textContainerOrigin.y - scrollOffset,
            width: bounds.width,
            height: lineRect.height
        )
        
        NSColor.selectedTextBackgroundColor.withAlphaComponent(0.2).setFill()
        NSBezierPath(rect: highlightRect).fill()
    }
    
    private func getVisibleGlyphRange(layoutManager: NSLayoutManager, textContainer: NSTextContainer) -> NSRange {
        guard let scrollView = scrollView else { return NSRange() }
        let visibleRect = scrollView.contentView.bounds
        return layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
    }
    
    private func drawLineNumbers(glyphRange: NSRange, layoutManager: NSLayoutManager) {
        guard let textView = textView,
              let scrollView = scrollView else { return }
        
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .right
                return style
            }()
        ]
        
        let scrollOffset = scrollView.contentView.bounds.minY
        let lineHeight = layoutManager.defaultLineHeight(for: font)
        var drawnLines = Set<Int>()
        
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, _, _, glyphRange, _ in
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            let lineNumber = self.lineNumber(at: charIndex, in: textView.string)
            guard drawnLines.insert(lineNumber).inserted else { return }
            
            let y = rect.minY + textView.textContainerOrigin.y - scrollOffset + (rect.height - lineHeight) / 2
            let numberRect = NSRect(
                x: self.padding,
                y: y,
                width: self.bounds.width - self.padding * 2,
                height: lineHeight
            )
            
            NSAttributedString(string: "\(lineNumber)", attributes: attributes).draw(in: numberRect)
        }
        
        // 🔹 캐럿이 위치한 현재 줄이 비어 있어도 번호가 보이도록 추가로 그린다
        let tv = textView
        let caretLine = self.lineNumber(at: tv.selectedRange.location, in: tv.string)
        if !drawnLines.contains(caretLine) {
            let caretGlyphIndex = layoutManager.glyphIndexForCharacter(at: tv.selectedRange.location)
            let caretRect = layoutManager.lineFragmentRect(forGlyphAt: caretGlyphIndex, effectiveRange: nil)
            let y = caretRect.minY + tv.textContainerOrigin.y - scrollOffset + (caretRect.height - lineHeight) / 2
            let numberRect = NSRect(
                x: self.padding,
                y: y,
                width: self.bounds.width - self.padding * 2,
                height: lineHeight
            )
            NSAttributedString(string: "\(caretLine)", attributes: attributes).draw(in: numberRect)
        }
    }
    
    private func lineNumber(at index: Int, in string: String) -> Int {
        let safeIndex = min(index, string.count)
        return string.prefix(safeIndex).reduce(1) { count, char in
            char == "\n" ? count + 1 : count
        }
    }
}

// MARK: - Preview
#if DEBUG
import SwiftUI

struct CodeEditorPreviewContainer: View {
    @State private var code: String = "Hello, World!\nfunc greet() {\n    print(\"Hi\")\n    let message = \"Welcome to Swift!\"\n    return message\n}"
    @State private var tags: [String] = []
    @State private var showTags: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Header with toggle button
            HStack {
                Text("Code Editor")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showTags.toggle()
                    if showTags {
                        // Trigger tag suggestion when enabling
                        generateTags()
                    } else {
                        // Clear tags when disabling
                        tags = []
                    }
                }) {
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
            }
            .padding(.horizontal)
            
            // Code editor
            CodeEditor(text: $code, suggestedTags: $tags, showSuggestedTags: $showTags)
                .frame(minWidth: 400, minHeight: 300)
                .border(Color.gray)

            // Show suggested tags as chips (only when showTags is true and tags exist)
            if showTags && !tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Suggested Tags:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Refresh", action: generateTags)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                Button(action: {
                                    insertTag(tag)
                                }) {
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
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private func generateTags() {
        Task {
            guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "openai") as? String, !apiKey.isEmpty else {
                print("⚠️ OPENAI_API_KEY not found in Info.plist under 'openai'")
                return
            }
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }

            // Local request/response models
            struct ChatRequest: Codable {
                let model: String
                let messages: [[String: String]]
                let temperature: Double
                let max_tokens: Int
            }
            struct ChatResponse: Codable {
                struct Choice: Codable { struct Message: Codable { let role: String; let content: String }; let index: Int?; let message: Message }
                let choices: [Choice]
            }

            let system = """
            You are a tagging assistant. Given arbitrary code/text, extract up to 8 short, general-purpose tags.
            Rules:
            - Lowercase
            - Use hyphen instead of spaces (e.g., error-handling)
            - No punctuation besides hyphen
            - Output MUST be a pure JSON array of strings, e.g., [\\"swift\\",\\"pdfkit\\"].
            Do not add any explanation.
            """

            let reqBody = ChatRequest(
                model: "gpt-4o-mini",
                messages: [
                    ["role": "system", "content": system],
                    ["role": "user", "content": code]
                ],
                temperature: 0.2,
                max_tokens: 200
            )

            do {
                let data = try JSONEncoder().encode(reqBody)
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.httpBody = data

                let (respData, resp) = try await URLSession.shared.data(for: request)
                if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                    let body = String(data: respData, encoding: .utf8) ?? ""
                    print("❌ OpenAI HTTP \(http.statusCode): \(body)")
                    return
                }

                let decoded = try JSONDecoder().decode(ChatResponse.self, from: respData)
                let content = decoded.choices.first?.message.content ?? ""

                // Try to parse strict JSON first
                func parseTags(from text: String) -> [String] {
                    if let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]") {
                        let slice = String(text[start...end])
                        if let d = slice.data(using: .utf8), let arr = try? JSONSerialization.jsonObject(with: d) as? [String] {
                            return arr
                        }
                    }
                    // Fallback: naive comma split
                    return text
                        .replacingOccurrences(of: "[", with: "")
                        .replacingOccurrences(of: "]", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                }

                let parsed = Array(parseTags(from: content).prefix(8))
                await MainActor.run { self.tags = parsed }
            } catch {
                print("❌ OpenAI error: \(error)")
            }
        }
    }
    
    private func insertTag(_ tag: String) {
        // Insert tag at current cursor position or append
        let insertion = "// #\(tag)\n"
        code += insertion
    }
}

struct CodeEditor_Previews: PreviewProvider {
    static var previews: some View {
        CodeEditorPreviewContainer()
            .frame(width: 600, height: 420)
    }
}
#endif
