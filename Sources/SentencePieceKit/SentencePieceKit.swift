import Foundation
import SentencePieceBridge

public final class SentencepieceTokenizer {
    private let bridge: SentencePieceBridge
    
    /// The offset applied to all token IDs. Useful for compatibility with other tokenizers (e.g. Hugging Face).
    public let tokenOffset: Int
    
    /// Initializes a new SentencePiece tokenizer.
    /// - Parameters:
    ///   - modelPath: The file path to the SentencePiece model (.model).
    ///   - tokenOffset: An optional offset to add to all token IDs. Defaults to 0.
    /// - Throws: An error if the model cannot be loaded (e.g. file not found, invalid format).
    public init(modelPath: String, tokenOffset: Int = 0) throws {
        self.bridge = try SentencePieceBridge(modelPath: modelPath)
        self.tokenOffset = tokenOffset
    }
    
    /// The ID for the Beginning of Sentence (BOS) token.
    public var bosTokenId: Int {
        return Int(bridge.bosId()) + tokenOffset
    }
    
    /// The ID for the End of Sentence (EOS) token.
    public var eosTokenId: Int {
        return Int(bridge.eosId()) + tokenOffset
    }
    
    /// The ID for the Unknown (UNK) token.
    public var unkTokenId: Int {
        return Int(bridge.unkId()) + tokenOffset
    }

    /// The ID for the Padding (PAD) token.
    public var padTokenId: Int {
        return Int(bridge.padId()) + tokenOffset
    }
    
    /// Encodes a text string into a sequence of token IDs.
    /// - Parameter text: The input string to tokenize.
    /// - Returns: An array of token IDs representing the input text.
    public func encode(_ text: String) -> [Int] {
        let rawIds = bridge.encode(text) as? [Int] ?? []
        guard tokenOffset != 0 else { return rawIds }
        return rawIds.map { $0 + tokenOffset }
    }
    
    /// Decodes a sequence of token IDs back into a text string.
    /// - Parameter ids: The array of token IDs to decode.
    /// - Returns: The decoded string.
    public func decode(_ ids: [Int]) -> String {
        let rawIds: [Int]
        if tokenOffset != 0 {
            rawIds = ids.map { $0 - tokenOffset }
        } else {
            rawIds = ids
        }
        return bridge.decode(rawIds as [NSNumber])
    }

    // MARK: - Async Support

    /// Asynchronously loads a SentencePiece model.
    /// Use this to avoid blocking the main thread during heavy file I/O and initialization.
    public static func load(modelPath: String, tokenOffset: Int = 0) async throws -> SentencepieceTokenizer {
        return try await Task.detached(priority: .userInitiated) {
            return try SentencepieceTokenizer(modelPath: modelPath, tokenOffset: tokenOffset)
        }.value
    }

    /// Asynchronously encodes a text string into a sequence of token IDs.
    public func encode(_ text: String) async -> [Int] {
        return await Task.detached(priority: .userInitiated) {
            return self.encode(text)
        }.value
    }

    /// Asynchronously decodes a sequence of token IDs back into a text string.
    public func decode(_ ids: [Int]) async -> String {
        return await Task.detached(priority: .userInitiated) {
            return self.decode(ids)
        }.value
    }
    
    /// Encodes text and prepares it for model inference with padding, truncation, and special tokens.
    /// - Parameters:
    ///   - text: The input text to tokenize.
    ///   - maxLength: The maximum length of the sequence (default: 128).
    ///   - addSpecialTokens: Whether to add BOS and EOS tokens (default: true).
    /// - Returns: A tuple containing the processed token IDs and the attention mask.
    public func tokenize(text: String, maxLength: Int = 128, addSpecialTokens: Bool = true) async -> (ids: [Int], mask: [Int]) {
        return await Task.detached(priority: .userInitiated) {
             // 1. Raw Encoding
            var ids = self.encode(text) // Use the synchronous internal encode
            
            // 2. Add Special Tokens
            if addSpecialTokens {
                ids = [self.bosTokenId] + ids + [self.eosTokenId]
            }
            
            // 3. Padding & Truncation
            let count = ids.count
            if count > maxLength {
                ids = Array(ids.prefix(maxLength))
            } else {
                let padCount = maxLength - count
                if padCount > 0 {
                    ids += Array(repeating: self.padTokenId, count: padCount)
                }
            }
            
            // 4. Create Attention Mask
            // Valid tokens (including BOS/EOS) get 1, Padding gets 0
            var mask = Array(repeating: 0, count: maxLength)
            let validLength = min(count, maxLength)
            for i in 0..<validLength {
                mask[i] = 1
            }
            
            return (ids, mask)
        }.value
    }
}

// MARK: - Sendable Support
// The underlying C++ SentencePieceProcessor is immutable after loading and thread-safe for encoding/decoding.
extension SentencepieceTokenizer: @unchecked Sendable {}
