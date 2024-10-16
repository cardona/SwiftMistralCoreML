//
//  TextGenerator.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 3/10/24.
//

import Foundation
import CoreML


public final class TextGenerator {
    private let modelActor: ModelActor
    private let tokenizerParser: TokenizerParser
    private let bpeEncoder: BPEEncoder
    
    public init() throws {
        self.modelActor = ModelActor()
        self.tokenizerParser = try TokenizerParser()
        self.bpeEncoder = BPEEncoder(tokenizerParser: tokenizerParser)
    }
    
    public func generateText(messages: [Message], using parameters: MistralParameters, progressHandler: (@Sendable (String) -> Void)? = nil) async throws -> String {
        let mistralInput = try MistralInput(messages: messages, bpeEncoder: bpeEncoder, tokenizer: tokenizerParser)
        
        guard let eosTokenID = bpeEncoder.encode(text: tokenizerParser.eosToken).first else {
            throw TextGeneratorError.invalidEOSToken
        }
        guard let endInstructionTokenID = bpeEncoder.encode(text: tokenizerParser.bosToken).first else {
            throw TextGeneratorError.invalidEndInstructionToken
        }
        
        var generatedText = ""
        var currentInputIds = mistralInput.inputTokens
        let decodingStrategy = createDecodingStrategy(using: parameters)
        
        for _ in 0..<parameters.maxTokens {
            let predictedTokenID = try await modelActor.generateNextToken(currentInputIds: currentInputIds, decodingStrategy: decodingStrategy, modelType: parameters.modelType)
            
            currentInputIds.append(predictedTokenID)
            
            let word = bpeEncoder.decode(tokenIDs: [predictedTokenID])
            generatedText += word
            
            if let progressHandler = progressHandler {
                await MainActor.run {
                    progressHandler(word)
                }
            }
            
            if predictedTokenID == eosTokenID || predictedTokenID == endInstructionTokenID {
                return generatedText.cleanGeneratedText()
            }
        }
        return generatedText.cleanGeneratedText()
    }
    
    private func createDecodingStrategy(using parameters: MistralParameters) -> DecodingStrategy {
        switch parameters.algorithm {
        case .greedy:
            return GreedyDecodingStrategy()
        case .topK:
            if let topK = parameters.topK {
                return TopKDecodingStrategy(topK: topK)
            } else {
                return TopKDecodingStrategy(topK: 10)
            }
        }
    }
}

enum TextGeneratorError: Error {
    case invalidEOSToken
    case invalidEndInstructionToken
    case missingTopKValue
    case missingMistral7B
    case stateCreationError
    case inputCreationError
    case outputCastingError
}
