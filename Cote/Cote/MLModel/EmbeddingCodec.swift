//
//  EmbeddingCodec.swift
//  Cote
//
//  Created by 김예림 on 11/2/25.
//

import Foundation

enum EmbeddingCodec {
    static func encode(_ v: [Float]) -> Data {
        var copy = v
        return Data(bytes: &copy, count: v.count * MemoryLayout<Float>.size)
    }
    static func decode(_ data: Data) -> [Float] {
        let count = data.count / MemoryLayout<Float>.size
        return data.withUnsafeBytes { buf in
            Array(UnsafeBufferPointer<Float>(
                start: buf.bindMemory(to: Float.self).baseAddress!,
                count: count
            ))
        }
    }
}
