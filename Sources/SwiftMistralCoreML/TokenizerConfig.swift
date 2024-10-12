//
//  TokenizerConfig.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 29/9/24.
//


import Foundation

struct TokenizerConfig: Codable {
    let addBOSToken: Bool?
    let addEOSToken: Bool?
    let addPrefixSpace: Bool?
    let addedTokensDecoder: [String: AddedTokenDecoder]?
    let BOSToken: String?
    let chatTemplate: String?
    let cleanUpTokenizationSpaces: Bool?
    let EOSToken: String?
    let legacy: Bool?
    let modelMaxLength: Int?
    let padToken: String?
    let spModelKwargs: [String: String]?
    let spacesBetweenSpecialTokens: Bool?
    let tokenizerClass: String?
    let UNKToken: String?
    let useDefaultSystemPrompt: Bool?

    enum CodingKeys: String, CodingKey {
        case addBOSToken = "add_bos_token"
        case addEOSToken = "add_eos_token"
        case addPrefixSpace = "add_prefix_space"
        case addedTokensDecoder = "added_tokens_decoder"
        case BOSToken = "bos_token"
        case chatTemplate = "chat_template"
        case cleanUpTokenizationSpaces = "clean_up_tokenization_spaces"
        case EOSToken = "eos_token"
        case legacy
        case modelMaxLength = "model_max_length"
        case padToken = "pad_token"
        case spModelKwargs = "sp_model_kwargs"
        case spacesBetweenSpecialTokens = "spaces_between_special_tokens"
        case tokenizerClass = "tokenizer_class"
        case UNKToken = "unk_token"
        case useDefaultSystemPrompt = "use_default_system_prompt"
    }
}

struct AddedTokenDecoder: Codable {
    let content: String?
    let lstrip: Bool?
    let normalized: Bool?
    let rstrip: Bool?
    let singleWord: Bool?
    let special: Bool?

    enum CodingKeys: String, CodingKey {
        case content
        case lstrip
        case normalized
        case rstrip
        case singleWord = "single_word"
        case special
    }
}
