//
//  Tokenizer.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 29/9/24.
//


// MARK: - Main Structure
struct Tokenizer: Codable {
    let version: String?
    let truncation: String?
    let padding: String?
    let addedTokens: [AddedToken]?
    let normalizer: String?
    let preTokenizer: PreTokenizer?
    let postProcessor: PostProcessor?
    let decoder: DecoderData?
    let model: Model?
    
    enum CodingKeys: String, CodingKey {
        case version
        case truncation
        case padding
        case addedTokens = "added_tokens"
        case normalizer
        case preTokenizer = "pre_tokenizer"
        case postProcessor = "post_processor"
        case decoder
        case model
    }
}

// MARK: - Added Token
struct AddedToken: Codable {
    let id: Int?
    let content: String?
    let singleWord: Bool?
    let lstrip: Bool?
    let rstrip: Bool?
    let normalized: Bool?
    let special: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case singleWord = "single_word"
        case lstrip
        case rstrip
        case normalized
        case special
    }
}

// MARK: - PreTokenizer
struct PreTokenizer: Codable {
    let type: String?
    let replacement: String?
    let prependScheme: String?
    let split: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type
        case replacement
        case prependScheme = "prepend_scheme"
        case split
    }
}

// MARK: - PostProcessor
struct PostProcessor: Codable {
    let type: String?
    let single: [TokenStep]?
    let pair: [TokenStep]?
    let specialTokens: [String: SpecialToken]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case single
        case pair
        case specialTokens = "special_tokens"
    }
}

// MARK: - TokenStep
struct TokenStep: Codable {
    let specialToken: SpecialToken?
    let sequence: SequenceData?
    
    enum CodingKeys: String, CodingKey {
        case specialToken = "SpecialToken"
        case sequence = "Sequence"
    }
}

// MARK: - SpecialToken
struct SpecialToken: Codable {
    let id: String?
    let typeID: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case typeID = "type_id"
    }
}

// MARK: - Sequence
struct SequenceData: Codable {
    let id: String?
    let typeID: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case typeID = "type_id"
    }
}

// MARK: - Decoder
struct DecoderData: Codable {
    let type: String?
    let decoders: [DecoderStep]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case decoders
    }
}

// MARK: - DecoderStep
struct DecoderStep: Codable {
    let type: String?
    let pattern: Pattern?
    let content: String?
    let start: Int?
    let stop: Int?
    
    enum CodingKeys: String, CodingKey {
        case type
        case pattern
        case content
        case start
        case stop
    }
}

// MARK: - Pattern
struct Pattern: Codable {
    let string: String?
    
    enum CodingKeys: String, CodingKey {
        case string = "String"
    }
}

// MARK: - Model
struct Model: Codable {
    let type: String?
    let dropout: String?
    let unkToken: String?
    let continuingSubwordPrefix: String?
    let endOfWordSuffix: String?
    let fuseUnk: Bool?
    let byteFallback: Bool?
    let ignoreMerges: Bool?
    let vocab: [String: Int]?
    let merges: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case dropout
        case unkToken = "unk_token"
        case continuingSubwordPrefix = "continuing_subword_prefix"
        case endOfWordSuffix = "end_of_word_suffix"
        case fuseUnk = "fuse_unk"
        case byteFallback = "byte_fallback"
        case ignoreMerges = "ignore_merges"
        case vocab
        case merges
    }
}
