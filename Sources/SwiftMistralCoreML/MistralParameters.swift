//
//  MistralParameters.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 7/10/24.
//

public struct MistralParameters: Sendable {
    public let userInput: String
    public let systemPrompt: String
    public let algorithm: DecodingAlgorithm
    public let maxTokens: Int
    public let topK: Int?
    
    public init(userInput: String, systemPrompt: String, algorithm: DecodingAlgorithm, maxTokens: Int, topK: Int?) {
        self.userInput = userInput
        self.systemPrompt = systemPrompt
        self.algorithm = algorithm
        self.maxTokens = maxTokens
        self.topK = topK
    }
}
