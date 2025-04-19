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

    public init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        self.modelActor = ModelActor(configuration: configuration)
        self.tokenizerParser = try TokenizerParser()
        self.bpeEncoder = BPEEncoder(tokenizerParser: tokenizerParser)
    }

    public func generateText(
        messages: [Message],
        using parameters: MistralParameters,
        progressHandler: (@Sendable (String) -> Void)? = nil
    ) async throws -> String {
        try await generateTextInternal(
            messages: messages,
            using: parameters,
            progressHandler: progressHandler,
            tokenGenerator: modelActor.generateNextToken
        )
    }

    public func generateTextAsync(
        messages: [Message],
        using parameters: MistralParameters,
        progressHandler: (@Sendable (String) -> Void)? = nil
    ) async throws -> String {
        try await generateTextInternal(
            messages: messages,
            using: parameters,
            progressHandler: progressHandler,
            tokenGenerator: modelActor.generateNextTokenAsync
        )
    }

    private func generateTextInternal(
        messages: [Message],
        using parameters: MistralParameters,
        progressHandler: (@Sendable (String) -> Void)?,
        tokenGenerator: @escaping ([Int], DecodingStrategy, MistralType) async throws -> Int
    ) async throws -> String {
        let mistralInput = try MistralInput(messages: messages, bpeEncoder: bpeEncoder, tokenizer: tokenizerParser)

        let (eosTokenID, endInstructionTokenID) = try getSpecialTokens()

        var generatedText = ""
        var currentInputIds = mistralInput.inputTokens
        let decodingStrategy = createDecodingStrategy(using: parameters)

        for _ in 0..<parameters.maxTokens {
            let predictedTokenID = try await tokenGenerator(currentInputIds, decodingStrategy, parameters.modelType)

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

    private func getSpecialTokens() throws -> (eosToken: Int, endInstructionToken: Int) {
        guard let eosTokenID = bpeEncoder.encode(text: tokenizerParser.eosToken).first else {
            throw TextGeneratorError.invalidEOSToken
        }
        guard let endInstructionTokenID = bpeEncoder.encode(text: tokenizerParser.bosToken).first else {
            throw TextGeneratorError.invalidEndInstructionToken
        }
        return (eosTokenID, endInstructionTokenID)
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
