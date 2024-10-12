//
//  TextGenerator.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 3/10/24.
//

import Foundation
import CoreML

enum TextGeneratorError: Error {
    case invalidEOSToken
    case missingTopKValue
    case missingMistral7B
    case stateCreationError
    case inputCreationError
    case outputCastingError
}

actor ModelActor {
    private let model: StatefulMistral7BInstructInt4
    private let state: StatefulMistral7BInstructInt4State
    
    init() throws {
        self.model = try StatefulMistral7BInstructInt4(configuration: MLModelConfiguration())
        self.state = model.makeState()
    }
    
    func generateNextToken(currentInputIds: [Int], decodingStrategy: DecodingStrategy) throws -> Int {
        let inputIdsArray = try createInputIdsArray(tokens: currentInputIds)
        let causalMaskArray = try createCausalMaskArray(sequenceLength: currentInputIds.count)
        
        let modelInput = StatefulMistral7BInstructInt4Input(inputIds: inputIdsArray, causalMask: causalMaskArray)
        
        let prediction = try model.prediction(input: modelInput, using: model.makeState())
        
        return try decodingStrategy.nextToken(logitsArray: prediction.logits)
    }
    
    private func createInputIdsArray(tokens: [Int]) throws -> MLMultiArray {
        let sequenceLength = tokens.count
        let inputIdsArray = try MLMultiArray(shape: [1, NSNumber(value: sequenceLength)], dataType: .int32)
        for (index, tokenID) in tokens.enumerated() {
            inputIdsArray[[0, NSNumber(value: index)] as [NSNumber]] = NSNumber(value: tokenID)
        }
        return inputIdsArray
    }
    
    private func createCausalMaskArray(sequenceLength: Int) throws -> MLMultiArray {
        let causalMaskArray = try MLMultiArray(shape: [1, 1, NSNumber(value: sequenceLength), NSNumber(value: sequenceLength)], dataType: .float16)
        for i in 0..<sequenceLength {
            for j in 0..<sequenceLength {
                let maskValue: Float = i >= j ? 0.0 : -Float.infinity
                causalMaskArray[[0, 0, NSNumber(value: i), NSNumber(value: j)] as [NSNumber]] = NSNumber(value: maskValue)
            }
        }
        return causalMaskArray
    }
}


public final class TextGenerator {
    private let bpeEncoder: BPEEncoder
    private let tokenizerParser: TokenizerParser
    private let eosTokenID: Int
    private let endInstructionTokens: [Int]
    private let modelActor: ModelActor
    
    public init(bpeEncoder: BPEEncoder, tokenizerParser: TokenizerParser) throws {
        self.bpeEncoder = bpeEncoder
        self.tokenizerParser = tokenizerParser
        guard let eosTokenID = bpeEncoder.encode(text: "</s>").first else {
            throw TextGeneratorError.invalidEOSToken
        }
        self.eosTokenID = eosTokenID
        self.endInstructionTokens = bpeEncoder.encode(text: "[/INST]")
        self.modelActor = try ModelActor()
    }
    
    public func generateText(from initialTokens: [Int], using parameters: MistralParameters, progressHandler: (@Sendable (String) -> Void)? = nil) async throws -> String {
        var generatedText = ""
        var currentInputIds = initialTokens
        let decodingStrategy = self.createDecodingStrategy(using: parameters)
        
        for _ in 0..<parameters.maxTokens {
            let predictedTokenID = try await modelActor.generateNextToken(
                currentInputIds: currentInputIds,
                decodingStrategy: decodingStrategy
            )
            
            currentInputIds.append(predictedTokenID)
            
            let word = self.bpeEncoder.decode(tokenIDs: [predictedTokenID])
            generatedText += word
            
            if let progressHandler = progressHandler {
                await MainActor.run {
                    progressHandler(word)
                }
            }
            
            if predictedTokenID == self.eosTokenID ||
                currentInputIds.suffix(self.endInstructionTokens.count) == self.endInstructionTokens {
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
            guard let topK = parameters.topK else {
                return TopKDecodingStrategy(topK: 10)
            }
            return TopKDecodingStrategy(topK: topK)
        }
    }
}
