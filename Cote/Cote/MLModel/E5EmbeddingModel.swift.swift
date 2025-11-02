//
//  E5EmbeddingModel.swift.swift
//  Cote
//
//  Created by 김예림 on 11/2/25.
//

import Foundation
import CoreML

// MARK: - Tokenizer
final class WordPieceTokenizer {
    private var vocab: [String: Int] = [:]
    private let unkToken = "[UNK]"
    private let maxLength = 256

    init(vocabFileURL: URL) {
        do {
            let content = try String(contentsOf: vocabFileURL, encoding: .utf8)
            let lines = content.split(separator: "\n").map(String.init)
            for (index, token) in lines.enumerated() {
                vocab[token] = index
            }
        } catch {
            print("❌ Failed to load vocab:", error)
        }
    }

    func tokenize(_ text: String) -> [Int] {
        var tokens: [Int] = []
        let words = text.lowercased().split(separator: " ")

        for word in words {
            if let id = vocab[String(word)] {
                tokens.append(id)
            } else if let unkID = vocab[unkToken] {
                tokens.append(unkID)
            }
        }

        // padding
        if tokens.count < maxLength {
            tokens += Array(repeating: 0, count: maxLength - tokens.count)
        } else if tokens.count > maxLength {
            tokens = Array(tokens.prefix(maxLength))
        }

        return tokens
    }
}

// MARK: - E5 Embedding Model Wrapper
final class E5EmbeddingModel {
    private let model: E5SentenceEmbedding
    private let tokenizer: WordPieceTokenizer

    init() {
        // 모델 로드
        model = try! E5SentenceEmbedding(configuration: MLModelConfiguration())

        // vocab.txt 로드
        guard let vocabURL = Bundle.main.url(forResource: "vocab", withExtension: "txt") else {
            fatalError("❌ vocab.txt not found in bundle")
        }
        tokenizer = WordPieceTokenizer(vocabFileURL: vocabURL)
    }

    func embedding(for text: String) throws -> [Double] {
        let tokenIDs = tokenizer.tokenize(text)
        let attentionMask = tokenIDs.map { $0 == 0 ? 0 : 1 } // padding은 0

        guard let input_ids = try? MLMultiArray(tokenIDs.map { NSNumber(value: $0) }),
              let attn_mask = try? MLMultiArray(attentionMask.map { NSNumber(value: $0) }) else {
            throw NSError(domain: "EmbeddingError", code: -1)
        }

        let input = E5SentenceEmbeddingInput(input_ids: input_ids, attention_mask: attn_mask)
        let output = try model.prediction(input: input)
        return output.var_938.toArray()
    }
}

// MARK: - Helper
extension MLMultiArray {
    func toArray() -> [Double] {
        return (0..<count).map { self[$0].doubleValue }
    }

    convenience init(_ values: [NSNumber]) throws {
        try self.init(shape: [NSNumber(value: values.count)], dataType: .int32)
        for (i, v) in values.enumerated() {
            self[i] = v
        }
    }
}
