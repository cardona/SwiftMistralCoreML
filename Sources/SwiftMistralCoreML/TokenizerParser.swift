//
//  TokenizerParser.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 30/9/24.
//


import Foundation

public struct TokenizerParser {
    let encoder: [String: Int]
    let decoder: [Int: String]
    let bpeRanks: [String: Int]
    let unkToken: String
    let bosToken: String
    let eosToken: String
    let vocabSize: Int
    let maxTokens: Int = 2048
    let tokenizer: Tokenizer
    let tokenizerConfig: TokenizerConfig

    public init() throws {
        guard
            let tokenizerPath = Bundle.module.url(forResource: "tokenizer", withExtension: "json")?.relativePath,
            let tokenizerConfigPath = Bundle.module.url(forResource: "tokenizer_config", withExtension: "json")?.relativePath
        else {
            throw TokenizerParserError.missingFields
        }
        
        let tokenizerData = try Data(contentsOf: URL(fileURLWithPath: tokenizerPath))
        let tokenizerConfigData = try Data(contentsOf: URL(fileURLWithPath: tokenizerConfigPath))
        
        tokenizer = try JSONDecoder().decode(Tokenizer.self, from: tokenizerData)
        tokenizerConfig = try JSONDecoder().decode(TokenizerConfig.self, from: tokenizerConfigData)
        
        guard
              let vocab = tokenizer.model?.vocab,
              let merges = tokenizer.model?.merges,
              let unkToken = tokenizerConfig.UNKToken,
              let bosToken = tokenizerConfig.BOSToken,
              let eosToken = tokenizerConfig.EOSToken
        else {
            throw TokenizerParserError.missingFields
        }

        self.encoder = vocab
        self.decoder = Dictionary(uniqueKeysWithValues: vocab.map { ($0.value, $0.key) })
        self.vocabSize = vocab.count

        var bpeRanksDict = [String: Int]()
        for (index, merge) in merges.enumerated() {
            let pair = merge.split(separator: " ").map { String($0) }
            if pair.count == 2 {
                let pairStr = "\(pair[0]) \(pair[1])"
                bpeRanksDict[pairStr] = index
            }
        }
        self.bpeRanks = bpeRanksDict

        self.unkToken = unkToken
        self.bosToken = bosToken
        self.eosToken = eosToken
    }

    enum TokenizerParserError: Error {
        case invalidJSON
        case missingFields
    }
}
