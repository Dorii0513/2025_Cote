//
//  E5EmbeddingModel.swift.swift
//  Cote
//
//  Created by 김예림 on 11/2/25.
//

import Foundation
import CoreML
import SentencepieceTokenizer

final class SentencePieceTokenizer {
    private let processor: SentencepieceTokenizer
    private let maxLength = 256

    init(modelName: String = "sentencepiece.bpe", modelExtension: String = "model") {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: modelExtension) else {
            fatalError("❌ sentencepiece.bpe.model not found in bundle")
        }
        do {
            processor = try SentencepieceTokenizer(modelPath: url.path)
        } catch {
            fatalError("❌ Failed to load SentencePiece model: \(error)")
        }
    }

    func tokenize(_ text: String) -> [Int32] {
        do {
            // encode 결과를 [Int]로 받고 Int32로 변환
            let ids = try processor.encode(text).map { Int32($0) }

            if ids.count < maxLength {
                return ids + Array(repeating: Int32(0), count: maxLength - ids.count)
            } else if ids.count > maxLength {
                return Array(ids.prefix(maxLength))
            } else {
                return ids
            }
        } catch {
            print("❌ Tokenization error:", error)
            return Array(repeating: 0, count: maxLength)
        }
    }
}

// MARK: - E5 Embedding Model Wrapper
final class E5EmbeddingModel {
    private let model: E5SentenceEmbedding
    private let tokenizer: SentencePieceTokenizer

    init() {
        model = try! E5SentenceEmbedding(configuration: MLModelConfiguration())
        tokenizer = SentencePieceTokenizer()
    }

    func embedding(for text: String) throws -> [Double] {
        let prefixed = "query: \(text)"
        let tokenIDs = tokenizer.tokenize(prefixed)
        let attentionMask = tokenIDs.map { $0 == 0 ? 0 : 1 }

        // 2차원 배열 생성
        let shape: [NSNumber] = [1, NSNumber(value: tokenIDs.count)]
        let input_ids = try MLMultiArray(shape: shape, dataType: .int32)
        let attn_mask = try MLMultiArray(shape: shape, dataType: .int32)

        // 값 채우기
        for i in 0..<tokenIDs.count {
            input_ids[[0, NSNumber(value: i)]] = NSNumber(value: tokenIDs[i])
            attn_mask[[0, NSNumber(value: i)]] = NSNumber(value: attentionMask[i])
        }

        // CoreML
        let input = E5SentenceEmbeddingInput(input_ids: input_ids, attention_mask: attn_mask)
        let output = try model.prediction(input: input)

        return output.var_938.toArray()
    }
}

// MARK: - MLMultiArray Helper
extension MLMultiArray {
    func toArray() -> [Double] {
        (0..<count).map { self[$0].doubleValue }
    }

    convenience init(_ int32Values: [NSNumber]) throws {
        try self.init(shape: [NSNumber(value: int32Values.count)], dataType: .int32)
        for (i, v) in int32Values.enumerated() {
            self[i] = v
        }
    }
}


